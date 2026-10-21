import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../common/api_links.dart';
import '../dto/models/chat_message.dart';

/// Something the chat socket tells the bloc. The wire frames are documented at
/// `/api/docs/` (description of the API) and implemented in `backend/apps/chat/consumers.py`.
sealed class ChatEvent {
  /// Allows the events to have const constructors.
  const ChatEvent();
}

/// `message.new` — a message was stored (it also arrives for the sender's own sends).
final class ChatMessageArrived extends ChatEvent {
  /// The stored message; its sender carries only an id.
  final ChatMessage message;

  /// Carries the message.
  const ChatMessageArrived(this.message);
}

/// `message.ack` — the server stored the message sent with [clientMsgId].
final class ChatMessageAcked extends ChatEvent {
  /// Client id the send was made with.
  final String clientMsgId;

  /// Server id of the stored message.
  final int id;

  /// Carries the acknowledgement.
  const ChatMessageAcked(this.clientMsgId, this.id);
}

/// `message.read` — somebody read the conversation up to [messageId].
final class ChatReadReceipt extends ChatEvent {
  /// Who read.
  final String userId;

  /// Newest message they have read.
  final int messageId;

  /// Carries the receipt.
  const ChatReadReceipt(this.userId, this.messageId);
}

/// `presence` — a participant went online or offline.
final class ChatPresence extends ChatEvent {
  /// Who changed.
  final String userId;

  /// New state.
  final bool online;

  /// Carries the change.
  const ChatPresence(this.userId, this.online);
}

/// `presence.snapshot` — who is online right after connecting.
final class ChatPresenceSnapshot extends ChatEvent {
  /// Ids of the participants that are online.
  final Set<String> online;

  /// Carries the snapshot.
  const ChatPresenceSnapshot(this.online);
}

/// `revoked` / close 4403 — access to the conversation was withdrawn.
final class ChatRevoked extends ChatEvent {
  /// Builds the event.
  const ChatRevoked();
}

/// `error` — the server refused a frame (e.g. `rate_limited`, `invalid_message`).
final class ChatSocketError extends ChatEvent {
  /// Generic error code.
  final String code;

  /// Carries the code.
  const ChatSocketError(this.code);
}

/// The transport went up or down; the screen shows a reconnecting banner while down.
final class ChatLinkChanged extends ChatEvent {
  /// True once connected.
  final bool connected;

  /// Carries the link state.
  const ChatLinkChanged({required this.connected});
}

/// A live link to one conversation: a stream of [ChatEvent]s and the two
/// things a client may say. The repository hands out the WebSocket flavour for
/// the live backend and a scripted in-memory one for the mock backend.
abstract class ChatConnection {
  /// Events from the server, including link changes. Broadcast.
  Stream<ChatEvent> get events;

  /// Sends [body]; the server answers with `message.new` and `message.ack` for [clientMsgId].
  void send(String body, String clientMsgId);

  /// Tells the server the signed-in user has read up to [messageId].
  void markRead(int messageId);

  /// Closes the link for good (no reconnect).
  Future<void> close();
}

/// Opens a [ChatConnection] to one conversation; chosen once in `main()` (live socket or mock).
typedef ChatConnector = ChatConnection Function(String conversationId);

/// [ChatConnection] over `ws(s)://host/ws/chat/<id>/`, authenticated with the
/// `bearer, <token>` subprotocol pair (browsers cannot set headers on a
/// WebSocket, and a token in the URL would end up in proxy logs). It
/// reconnects with a growing delay until [close] is called, except when the
/// server closes with 4401/4403 (not signed in / no access).
class WebSocketChatConnection implements ChatConnection {
  /// Conversation to join.
  final String conversationId;

  /// Reads the current bearer token at every (re)connect, so a refreshed session is picked up.
  final String Function() token;

  /// Builds the connection and starts connecting.
  WebSocketChatConnection({required this.conversationId, required this.token}) {
    _open();
  }

  /// Longest wait between reconnect attempts.
  static const _maxBackoff = 15;

  /// Seconds between keep-alive pings (proxies drop idle sockets).
  static const _pingEvery = Duration(seconds: 25);

  final _events = StreamController<ChatEvent>.broadcast();
  WebSocketChannel? _channel;
  Timer? _ping;
  Timer? _retry;
  bool _closed = false;
  int _attempt = 0;

  @override
  Stream<ChatEvent> get events => _events.stream;

  /// Opens the socket; any failure schedules a retry.
  Future<void> _open() async {
    if (_closed) return;
    final channel = WebSocketChannel.connect(
      Uri.parse(ApiLinks.chatSocket(conversationId)),
      protocols: ['bearer', token()],
    );
    _channel = channel;
    try {
      await channel.ready;
    } catch (_) {
      return _down(channel);
    }
    if (_closed) return;
    _attempt = 0;
    _emit(const ChatLinkChanged(connected: true));
    _ping = Timer.periodic(_pingEvery, (_) => _write({'type': 'ping'}));
    channel.stream.listen(_onFrame, onDone: () => _down(channel), onError: (_) => _down(channel));
  }

  /// The socket [channel] ended: stop pinging and reconnect unless the close was final.
  void _down(WebSocketChannel channel) {
    if (!identical(channel, _channel)) return;
    _channel = null;
    _ping?.cancel();
    if (_closed) return;
    final code = channel.closeCode;
    if (code == 4401 || code == 4403) {
      _emit(const ChatRevoked());
      return;
    }
    _emit(const ChatLinkChanged(connected: false));
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
    switch (frame['type']) {
      case 'message.new':
        _emit(ChatMessageArrived(ChatMessage.fromJson((frame['message'] as Map).cast<String, dynamic>())));
      case 'message.ack':
        _emit(ChatMessageAcked('${frame['client_msg_id']}', (frame['id'] as num).toInt()));
      case 'message.read':
        _emit(ChatReadReceipt('${frame['user']}', (frame['message_id'] as num).toInt()));
      case 'presence':
        _emit(ChatPresence('${frame['user']}', frame['online'] == true));
      case 'presence.snapshot':
        _emit(ChatPresenceSnapshot({for (final id in (frame['online'] as List? ?? const [])) '$id'}));
      case 'revoked':
        _emit(const ChatRevoked());
      case 'error':
        _emit(ChatSocketError('${frame['code']}'));
    }
  }

  void _emit(ChatEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  /// Writes a JSON frame if the socket is up.
  void _write(Map<String, dynamic> frame) => _channel?.sink.add(jsonEncode(frame));

  @override
  void send(String body, String clientMsgId) =>
      _write({'type': 'message.send', 'body': body, 'client_msg_id': clientMsgId});

  @override
  void markRead(int messageId) => _write({'type': 'message.read', 'message_id': messageId});

  @override
  Future<void> close() async {
    _closed = true;
    _ping?.cancel();
    _retry?.cancel();
    await _channel?.sink.close();
    await _events.close();
  }
}
