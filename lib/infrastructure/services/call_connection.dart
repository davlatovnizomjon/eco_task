import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../common/api_links.dart';
import '../dto/models/call_model.dart';

/// Something the personal socket tells the call layer. Frames are implemented in `backend/apps/chat/consumers.py`
/// (`UserConsumer`).
sealed class CallSocketEvent {
  /// Allows the events to have const constructors.
  const CallSocketEvent();
}

/// `call.incoming`, `call.answered`, `call.declined` or `call.ended` — the call changed.
final class CallChanged extends CallSocketEvent {
  /// Which change: `incoming`, `answered`, `declined` or `ended`.
  final String change;

  /// The call as it is now.
  final CallModel call;

  /// Carries the change.
  const CallChanged(this.change, this.call);
}

/// `call.signal` — a WebRTC message (offer, answer, ICE candidate, state) from another participant.
final class CallSignalArrived extends CallSocketEvent {
  /// Call the message belongs to.
  final int callId;

  /// Sender's account id.
  final String from;

  /// Opaque payload; its shape is agreed between the two apps (see `CallMedia`).
  final Map<String, dynamic> data;

  /// Carries the signal.
  const CallSignalArrived(this.callId, this.from, this.data);
}

/// The transport went up or down.
final class CallLinkChanged extends CallSocketEvent {
  /// True once connected.
  final bool connected;

  /// Carries the link state.
  const CallLinkChanged({required this.connected});
}

/// The signed-in person's live link for calls: a stream of [CallSocketEvent]s and the one thing a client may say
/// (relay a signal to another participant). The app root hands out the WebSocket flavour for the live backend
/// and an idle one for the mock backend.
abstract class CallConnection {
  /// Events from the server, including link changes. Broadcast.
  Stream<CallSocketEvent> get events;

  /// Relays [data] to [to] inside call [callId]; the server refuses it unless both are in the live call.
  void sendSignal(int callId, String to, Map<String, dynamic> data);

  /// Closes the link for good (no reconnect).
  Future<void> close();
}

/// Opens a [CallConnection]; chosen once in `main()` (live socket or idle mock).
typedef CallConnector = CallConnection Function();

/// [CallConnection] that never produces anything: the mock backend has no ringing devices.
class IdleCallConnection implements CallConnection {
  /// Builds the idle link.
  IdleCallConnection();

  final _events = StreamController<CallSocketEvent>.broadcast();

  @override
  Stream<CallSocketEvent> get events => _events.stream;

  @override
  void sendSignal(int callId, String to, Map<String, dynamic> data) {}

  @override
  Future<void> close() => _events.close();
}

/// [CallConnection] over `ws(s)://host/ws/me/`, authenticated with the `bearer, <token>` subprotocol pair like the
/// chat socket. It reconnects with a growing delay until [close] is called, except when the server closes with
/// 4401/4403 (not signed in / refused).
class WebSocketCallConnection implements CallConnection {
  /// Reads the current bearer token at every (re)connect, so a refreshed session is picked up.
  final String Function() token;

  /// Builds the connection and starts connecting.
  WebSocketCallConnection({required this.token}) {
    _open();
  }

  /// Longest wait between reconnect attempts.
  static const _maxBackoff = 15;

  /// Seconds between keep-alive pings (proxies drop idle sockets).
  static const _pingEvery = Duration(seconds: 25);

  final _events = StreamController<CallSocketEvent>.broadcast();
  WebSocketChannel? _channel;
  Timer? _ping;
  Timer? _retry;
  bool _closed = false;
  int _attempt = 0;

  @override
  Stream<CallSocketEvent> get events => _events.stream;

  /// Opens the socket; any failure schedules a retry.
  Future<void> _open() async {
    if (_closed) return;
    final channel = WebSocketChannel.connect(Uri.parse(ApiLinks.meSocket), protocols: ['bearer', token()]);
    _channel = channel;
    try {
      await channel.ready;
    } catch (_) {
      return _down(channel);
    }
    if (_closed) return;
    _attempt = 0;
    _emit(const CallLinkChanged(connected: true));
    _ping = Timer.periodic(_pingEvery, (_) => _write({'type': 'ping'}));
    channel.stream.listen(_onFrame, onDone: () => _down(channel), onError: (_) => _down(channel));
  }

  /// The socket [channel] ended: stop pinging and reconnect unless the close was final.
  void _down(WebSocketChannel channel) {
    if (!identical(channel, _channel)) return;
    _channel = null;
    _ping?.cancel();
    if (_closed) return;
    _emit(const CallLinkChanged(connected: false));
    final code = channel.closeCode;
    if (code == 4401 || code == 4403) return;
    _retry = Timer(Duration(seconds: _attempt < 4 ? 1 << _attempt : _maxBackoff), _open);
    _attempt++;
  }

  /// Decodes one server frame into an event.
  void _onFrame(dynamic raw) {
    final Map<String, dynamic> frame;
    try {
      frame = (jsonDecode('$raw') as Map).cast<String, dynamic>();
    } catch (_) {
      return;
    }
    final type = '${frame['type']}';
    if (type == 'call.signal') {
      final data = frame['data'];
      if (data is Map) {
        _emit(CallSignalArrived((frame['call'] as num).toInt(), '${frame['from']}', data.cast<String, dynamic>()));
      }
    } else if (type.startsWith('call.') && frame['call'] is Map) {
      _emit(CallChanged(type.substring(5), CallModel.fromJson((frame['call'] as Map).cast<String, dynamic>())));
    }
  }

  void _emit(CallSocketEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  /// Writes a JSON frame if the socket is up.
  void _write(Map<String, dynamic> frame) => _channel?.sink.add(jsonEncode(frame));

  @override
  void sendSignal(int callId, String to, Map<String, dynamic> data) =>
      _write({'type': 'call.signal', 'call': callId, 'to': int.tryParse(to) ?? 0, 'data': data});

  @override
  Future<void> close() async {
    _closed = true;
    _ping?.cancel();
    _retry?.cancel();
    await _channel?.sink.close();
    await _events.close();
  }
}
