import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/common/enums/call_kind.dart';
import '../../domain/common/enums/call_party_state.dart';
import '../common/api_links.dart';
import '../common/dio_client.dart';
import '../dto/models/call_model.dart';
import '../services/call_connection.dart';
import '../services/call_media.dart';

/// Calls: REST for starting, answering, declining, ending and inviting, plus the personal live link that delivers
/// ringing calls and relays WebRTC signals. Provided once at the app root; the link is opened by the signed-in
/// shell ([connect]) and closed with it ([disconnect]).
class CallRepository {
  /// Opens the personal live link (WebSocket, or the idle mock).
  final CallConnector connector;

  /// Builds the repository over [connector].
  CallRepository({required this.connector});

  /// The call that is ringing for the signed-in person right now; null when none. The shell shows the incoming
  /// screen for it and clears it with [dismissIncoming].
  final ValueNotifier<CallModel?> incoming = ValueNotifier(null);

  /// The live call the signed-in person is in (or is starting); null when none. It outlives the call screen, so the
  /// screen can be minimized and reopened while the conversation goes on.
  final ValueNotifier<CallModel?> active = ValueNotifier(null);

  /// Media sessions of the calls in progress, by call id; they live here so they survive the call screen.
  final Map<int, CallMedia> _media = {};

  /// Id of the signed-in person, set by [connect]; decides which parties of a call are "me".
  String _meId = '';

  final _changes = StreamController<CallChanged>.broadcast();
  final _signals = StreamController<CallSignalArrived>.broadcast();
  CallConnection? _link;
  StreamSubscription<CallSocketEvent>? _sub;

  /// Every change of a call the server pushed (answered, declined, ended, ...).
  Stream<CallChanged> get changes => _changes.stream;

  /// Every WebRTC signal addressed to this device.
  Stream<CallSignalArrived> get signals => _signals.stream;

  /// Opens the live link for the person [meId] if it is not open yet.
  void connect(String meId) {
    _meId = meId;
    if (_link != null) return;
    final link = connector();
    _link = link;
    _sub = link.events.listen((event) {
      switch (event) {
        case CallChanged():
          _onChanged(event);
        case CallSignalArrived():
          _media[event.callId]?.onSignal(event.from, event.data);
          _signals.add(event);
        case CallLinkChanged():
          break;
      }
    });
  }

  /// Keeps [incoming], [active] and the media sessions in step with a change the server pushed.
  void _onChanged(CallChanged event) {
    final call = event.call;
    if (event.change == 'incoming') incoming.value = call;
    if (!call.status.isLive || call.stateOf(_meId) != CallPartyState.invited) {
      if (incoming.value?.id == call.id) incoming.value = null;
    }
    if (active.value?.id == call.id) {
      active.value = call.status.isLive && call.stateOf(_meId) == CallPartyState.joined ? call : null;
      final media = _media[call.id];
      if (media != null) {
        if (active.value == null) {
          releaseMedia(call.id);
        } else {
          for (final p in call.parties) {
            if (p.user.id != _meId && p.state != CallPartyState.joined && p.state != CallPartyState.invited) {
              media.drop(p.user.id);
            }
          }
        }
      }
    }
    _changes.add(event);
  }

  /// The media session of call [callId], created on first use.
  CallMedia mediaFor(int callId) => _media.putIfAbsent(callId, () => createMedia(callId));

  /// Hangs the media session of call [callId] up: closes its connections and frees the microphone and camera.
  Future<void> releaseMedia(int callId) async => _media.remove(callId)?.dispose();

  /// Closes the live link (sign-out).
  Future<void> disconnect() async {
    for (final id in _media.keys.toList()) {
      await releaseMedia(id);
    }
    active.value = null;
    await _sub?.cancel();
    await _link?.close();
    _sub = null;
    _link = null;
    incoming.value = null;
  }

  /// Marks the ringing call as handled by the UI.
  void dismissIncoming() => incoming.value = null;

  /// Builds the media layer of one call wired to this repository's signalling.
  CallMedia createMedia(int callId) => CallMedia(send: (to, data) => _link?.sendSignal(callId, to, data));

  /// Starts a call in conversation [conversationId]; the other members start ringing.
  Future<CallModel> start(String conversationId, CallKind kind) async =>
      _parse((await dioClient.post(ApiLinks.conversationCalls(conversationId), data: {'kind': kind.apiName})).data);

  /// Loads one call.
  Future<CallModel> get(int id) async => _parse((await dioClient.get(ApiLinks.call(id))).data);

  /// Answers a ringing call.
  Future<CallModel> answer(int id) async => _parse((await dioClient.post(ApiLinks.callAction(id, 'answer'))).data);

  /// Declines a ringing call.
  Future<CallModel> decline(int id) async => _parse((await dioClient.post(ApiLinks.callAction(id, 'decline'))).data);

  /// Hangs up (or cancels a call nobody answered yet).
  Future<CallModel> end(int id) async => _parse((await dioClient.post(ApiLinks.callAction(id, 'end'))).data);

  /// Adds people of the group to a live group call; they start ringing.
  Future<CallModel> invite(int id, List<String> userIds) async => _parse(
    (await dioClient.post(
      ApiLinks.callAction(id, 'invite'),
      data: {
        'user_ids': [for (final u in userIds) int.parse(u)],
      },
    )).data,
  );

  /// Parses a call payload.
  CallModel _parse(Object? data) => CallModel.fromJson((data as Map).cast<String, dynamic>());

  /// Releases the live link and the streams with the app.
  void dispose() {
    for (final media in _media.values) {
      media.dispose();
    }
    _media.clear();
    active.dispose();
    _sub?.cancel();
    _link?.close();
    _changes.close();
    _signals.close();
    incoming.dispose();
  }
}
