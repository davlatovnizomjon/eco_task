import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/app_config.dart';
import 'package:eco_task/domain/common/enums/call_kind.dart';
import 'package:eco_task/domain/common/enums/call_party_state.dart';
import 'package:eco_task/domain/common/enums/call_status.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/call_model.dart';
import 'package:eco_task/infrastructure/dto/models/conversation_model.dart';
import 'package:eco_task/infrastructure/repository/call_repository.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/infrastructure/services/call_media.dart';

part 'event.dart';
part 'state.dart';

/// Drives the call screen: starts or loads one call, answers / declines / ends it, runs the timer, keeps the
/// microphone / speaker / camera controls and reacts to what the server pushes (people answering, declining, leaving).
/// The audio and video session itself lives in [CallRepository], so the screen can be minimized without cutting the call.
class CallBloc extends Bloc<CallEvent, CallState> {
  /// Call data source and media sessions; owned by the app root.
  final CallRepository repository;

  /// Source of the conversation (title, kind, members).
  final ChatRepository chats;

  /// Id of the signed-in person.
  final String meId;

  /// Id of the call to show, or `new` to start one in [conversationId].
  final String callId;

  /// Conversation to call when [callId] is `new`.
  final String conversationId;

  /// Media of the call to start when [callId] is `new`.
  final CallKind kind;

  /// Wires the handlers of the screen.
  CallBloc({
    required this.repository,
    required this.chats,
    required this.meId,
    required this.callId,
    this.conversationId = '',
    this.kind = CallKind.audio,
  }) : super(const CallState()) {
    on<CallStarted>(_onStarted);
    on<CallAnswered>(_onAnswered);
    on<CallDeclined>(_onDeclined);
    on<CallEnded>(_onEnded);
    on<CallRedialed>(_onRedialed);
    on<CallMuteToggled>(_onMute);
    on<CallSpeakerToggled>(_onSpeaker);
    on<CallVideoToggled>(_onVideo);
    on<CallCameraFlipped>(_onFlip);
    on<CallInvited>(_onInvited);
    on<CallPageChanged>((e, emit) => emit(state.copyWith(page: e.page)));
    on<CallNoticeCleared>((e, emit) => emit(state.copyWith(notice: null)));
    on<_CallPushed>(_onPushed);
    on<_CallTicked>(_onTicked);
  }

  StreamSubscription<dynamic>? _changes;
  Timer? _ticker;
  Timer? _noticeTimer;

  /// The audio/video session of the shown call; null on the mock backend (no real media there).
  CallMedia? get media {
    final id = state.call?.id;
    return id == null || AppConfig.useMockData ? null : repository.mediaFor(id);
  }

  /// Whether the signed-in person is the one who started the shown call.
  bool get isCaller => state.call?.caller?.id == meId;

  /// Loads or starts the call, then attaches to it.
  Future<void> _onStarted(CallStarted event, Emitter<CallState> emit) async {
    emit(state.copyWith(status: ScreenStatus.loading));
    try {
      final CallModel call;
      if (callId == 'new') {
        final running = repository.active.value;
        call = running != null && running.conversationId == conversationId
            ? running
            : await repository.start(conversationId, kind);
      } else {
        call = await repository.get(int.parse(callId));
      }
      final conversation = await chats.getConversation(call.conversationId);
      emit(
        state.copyWith(
          status: ScreenStatus.success,
          call: call,
          conversation: conversation,
          video: call.kind == CallKind.video,
        ),
      );
      await _attach(call);
    } catch (e) {
      emit(
        state.copyWith(
          status: ScreenStatus.error,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
          closeScreen: true,
        ),
      );
    }
  }

  /// Starts listening to [call]: server pushes and the timer, and opens the media when the person is already in it.
  Future<void> _attach(CallModel call) async {
    await _changes?.cancel();
    _changes = repository.changes.where((e) => e.call.id == call.id).listen((e) => add(_CallPushed(e.call)));
    if (call.stateOf(meId) == CallPartyState.joined && call.status.isLive) {
      repository.active.value = call;
      await media?.open(video: call.kind == CallKind.video);
    }
    _syncTicker(call);
  }

  /// Runs the one-second timer exactly while the call is active.
  void _syncTicker(CallModel call) {
    if (call.status == CallStatus.active) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => add(const _CallTicked()));
      add(const _CallTicked());
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  /// Joins the ringing call and starts talking to everybody who is already in it.
  Future<void> _onAnswered(CallAnswered event, Emitter<CallState> emit) async {
    final current = state.call;
    if (current == null) return;
    emit(state.copyWith(busy: true));
    try {
      final call = await repository.answer(current.id);
      repository.dismissIncoming();
      repository.active.value = call;
      final m = media;
      if (m != null) {
        await m.open(video: call.kind == CallKind.video);
        for (final user in call.joined.where((u) => u.id != meId)) {
          unawaited(m.connectTo(user.id));
        }
      }
      emit(state.copyWith(busy: false, call: call, video: call.kind == CallKind.video));
      _syncTicker(call);
    } catch (e) {
      emit(
        state.copyWith(
          busy: false,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
          closeScreen: true,
        ),
      );
    }
  }

  /// Refuses the ringing call and closes the screen.
  Future<void> _onDeclined(CallDeclined event, Emitter<CallState> emit) async {
    final current = state.call;
    if (current == null) return;
    emit(state.copyWith(busy: true));
    try {
      await repository.decline(current.id);
    } catch (_) {
      // The call may already be over; either way the ring stops here.
    }
    repository.dismissIncoming();
    emit(state.copyWith(busy: false, closeScreen: true));
  }

  /// Leaves the call (cancels it while it rings), frees the media and closes the screen.
  Future<void> _onEnded(CallEnded event, Emitter<CallState> emit) async {
    final current = state.call;
    if (current == null) return emit(state.copyWith(closeScreen: true));
    emit(state.copyWith(busy: true));
    try {
      await repository.end(current.id);
    } catch (_) {
      // Already over on the server; clean up locally all the same.
    }
    await repository.releaseMedia(current.id);
    repository.active.value = null;
    emit(state.copyWith(busy: false, closeScreen: true));
  }

  /// Starts a fresh call in the same conversation after a refused or unanswered one.
  Future<void> _onRedialed(CallRedialed event, Emitter<CallState> emit) async {
    final current = state.call;
    if (current == null) return;
    emit(state.copyWith(busy: true));
    try {
      final call = await repository.start(current.conversationId, current.kind);
      emit(state.copyWith(busy: false, call: call, notice: null, seconds: 0, video: call.kind == CallKind.video));
      await _attach(call);
    } catch (e) {
      emit(state.copyWith(busy: false, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }

  /// Flips the microphone.
  void _onMute(CallMuteToggled event, Emitter<CallState> emit) {
    media?.setMuted(!state.muted);
    emit(state.copyWith(muted: !state.muted));
  }

  /// Flips the loudspeaker.
  Future<void> _onSpeaker(CallSpeakerToggled event, Emitter<CallState> emit) async {
    await media?.setSpeaker(!state.speaker);
    emit(state.copyWith(speaker: !state.speaker));
  }

  /// Flips the camera.
  Future<void> _onVideo(CallVideoToggled event, Emitter<CallState> emit) async {
    try {
      await media?.setVideo(!state.video);
      emit(state.copyWith(video: !state.video));
    } catch (_) {
      emit(state.copyWith(response: const UnExpectedErrorResponse()));
    }
  }

  /// Switches between the front and back camera.
  Future<void> _onFlip(CallCameraFlipped event, Emitter<CallState> emit) async {
    await media?.flipCamera();
    emit(state.copyWith(front: !state.front));
  }

  /// Rings the people picked in the "add to call" sheet.
  Future<void> _onInvited(CallInvited event, Emitter<CallState> emit) async {
    final current = state.call;
    if (current == null || event.userIds.isEmpty) return;
    try {
      emit(state.copyWith(call: await repository.invite(current.id, event.userIds)));
    } catch (e) {
      emit(state.copyWith(response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }

  /// Applies a server push: new party states, a refused invitation, or the end of the call.
  void _onPushed(_CallPushed event, Emitter<CallState> emit) {
    final call = event.call;
    final before = state.call;
    String? notice;
    if (before != null) {
      for (final p in call.parties) {
        if (p.state == CallPartyState.declined &&
            before.stateOf(p.user.id) != CallPartyState.declined &&
            p.user.id != meId) {
          notice = p.user.name;
        }
      }
    }
    final callerSeesResult = isCaller && call.status != CallStatus.ended && call.status != CallStatus.canceled;
    final over = !call.status.isLive;
    emit(
      state.copyWith(
        call: call,
        notice: notice ?? state.notice,
        // A finished call shows its result only to the person who started it; everyone else just leaves.
        closeScreen: over && !(callerSeesResult && state.call?.status != null),
      ),
    );
    if (notice != null) {
      _noticeTimer?.cancel();
      _noticeTimer = Timer(const Duration(seconds: 3), () => add(const CallNoticeCleared()));
    }
    _syncTicker(call);
    if (over) repository.releaseMedia(call.id);
  }

  /// Advances the call timer.
  void _onTicked(_CallTicked event, Emitter<CallState> emit) {
    final answered = state.call?.answeredAt;
    if (answered == null) return;
    emit(state.copyWith(seconds: DateTime.now().difference(answered).inSeconds.clamp(0, 86399)));
  }

  @override
  Future<void> close() {
    _changes?.cancel();
    _ticker?.cancel();
    _noticeTimer?.cancel();
    return super.close();
  }
}
