import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/media_picker.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/app_user.dart';
import 'package:eco_task/infrastructure/dto/models/chat_message.dart';
import 'package:eco_task/infrastructure/dto/models/conversation_model.dart';
import 'package:eco_task/infrastructure/dto/models/file_attachment.dart';
import 'package:eco_task/infrastructure/dto/models/user_ref.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/infrastructure/repository/files_repository.dart';
import 'package:eco_task/infrastructure/services/chat_connection.dart';

part 'event.dart';
part 'state.dart';

/// Drives one conversation: loads it and its newest history, joins the live
/// socket, sends messages optimistically (socket first, REST when the socket
/// is down or silent) and keeps the read marker moving.
///
/// The screen is opened with a [conversationId], or with a [taskId] whose
/// discussion is opened (created on first use) before anything else.
class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  /// Data source of chats; owned by the app root.
  final ChatRepository repository;

  /// Uploads of the files that travel with messages.
  final FilesRepository files;

  /// The signed-in user, who authors every send.
  final AppUser me;

  /// Conversation to show, or null when [taskId] is given.
  final String? conversationId;

  /// Task whose chat to open, or null when [conversationId] is given.
  final String? taskId;

  /// Seconds to wait for a socket acknowledgement before falling back to REST.
  static const _ackTimeout = Duration(seconds: 8);

  /// Id of the loaded conversation.
  late String _id;

  ChatConnection? _connection;
  StreamSubscription<ChatEvent>? _subscription;
  final Map<String, Timer> _ackTimers = {};
  int _sent = 0;

  /// True once the first link came up (that one needs no resync; later ones do).
  bool _linkedOnce = false;

  /// Wires the handlers of the conversation.
  ConversationBloc({required this.repository, required this.files, required this.me, this.conversationId, this.taskId})
    : super(const ConversationState()) {
    on<ConversationStarted>(_onStarted);
    on<ConversationOlderRequested>(_onOlder);
    on<ConversationMessageSent>(_onSent);
    on<ConversationFileSent>(_onFileSent);
    on<ConversationReplyChanged>((event, emit) => emit(state.copyWith(replyingTo: event.message)));
    on<ConversationMessageRetried>(_onRetried);
    on<ConversationSocketEvent>(_onSocket);
    on<ConversationSendTimedOut>(_onTimedOut);
    on<ConversationMessageEdited>(
      (event, emit) => _change(emit, () => repository.editMessage(_id, event.id, event.text)),
    );
    on<ConversationMessageDeleted>((event, emit) => _change(emit, () => repository.deleteMessage(_id, event.id)));
    on<ConversationReacted>((event, emit) => _change(emit, () => repository.react(_id, event.id, event.emoji)));
    on<ConversationPinned>(_onPinned);
  }

  /// Presents a failure of [e].
  ScreenResponse _failure(Object e) => e is ScreenResponse ? e : const UnExpectedErrorResponse();

  /// Loads the conversation and the newest page, then joins the socket.
  Future<void> _onStarted(ConversationStarted event, Emitter<ConversationState> emit) async {
    emit(state.copyWith(status: ScreenStatus.loading));
    try {
      final conversation = conversationId != null
          ? await repository.getConversation(conversationId!)
          : await repository.openTaskChat(taskId!);
      _id = conversation.id;
      final history = await repository.getMessages(_id);
      emit(
        state.copyWith(
          conversation: conversation,
          messages: history.messages,
          hasMore: history.hasMore,
          status: ScreenStatus.success,
        ),
      );
      _connection = repository.connect(_id);
      _subscription = _connection!.events.listen((e) => add(ConversationSocketEvent(e)));
      _markRead(history.messages);
    } catch (e) {
      emit(state.copyWith(status: ScreenStatus.error, response: _failure(e)));
    }
  }

  /// Prepends the next older page.
  Future<void> _onOlder(ConversationOlderRequested event, Emitter<ConversationState> emit) async {
    final oldest = state.messages.where((m) => m.id != 0).firstOrNull;
    if (state.loadingOlder || !state.hasMore || oldest == null) return;
    emit(state.copyWith(loadingOlder: true));
    try {
      final page = await repository.getMessages(_id, before: oldest.id);
      emit(state.copyWith(messages: _merge(state.messages, page.messages), hasMore: page.hasMore, loadingOlder: false));
    } catch (e) {
      emit(state.copyWith(loadingOlder: false, response: _failure(e)));
    }
  }

  /// Adds the message optimistically and sends it.
  Future<void> _onSent(ConversationMessageSent event, Emitter<ConversationState> emit) async {
    final text = event.text.trim();
    if (text.isEmpty || state.conversation == null) return;
    await _compose(text, null, emit);
  }

  /// Uploads the file, then sends it as a message of its own.
  Future<void> _onFileSent(ConversationFileSent event, Emitter<ConversationState> emit) async {
    if (state.conversation == null || state.uploading) return;
    emit(state.copyWith(uploading: true));
    try {
      final stored = await files.uploadPicked(event.file);
      emit(state.copyWith(uploading: false));
      await _compose('', stored, emit);
    } catch (e) {
      emit(state.copyWith(uploading: false, response: _failure(e)));
    }
  }

  /// Adds an optimistic message (answering the reply bar's message, if any) and sends it.
  Future<void> _compose(String text, FileAttachment? attachment, Emitter<ConversationState> emit) async {
    final parent = state.replyingTo;
    final pending = ChatMessage(
      id: 0,
      conversationId: _id,
      sender: me.ref,
      body: text,
      clientMsgId: '${me.id}-${DateTime.now().microsecondsSinceEpoch}-${_sent++}',
      at: DateTime.now(),
      delivery: ChatDelivery.sending,
      attachment: attachment,
      replyTo: parent == null
          ? null
          : ChatReply(
              id: parent.id,
              senderName: parent.sender.name,
              body: parent.body.length > 120 ? parent.body.substring(0, 120) : parent.body,
              attachmentKind: parent.attachment?.kind,
            ),
    );
    emit(state.copyWith(messages: [...state.messages, pending], replyingTo: null));
    await _deliver(pending, emit);
  }

  /// Sends a pending message over the socket (with a REST fallback timer) or straight over REST.
  Future<void> _deliver(ChatMessage pending, Emitter<ConversationState> emit) async {
    if (state.connected && _connection != null) {
      _connection!.send(
        pending.body,
        pending.clientMsgId,
        replyTo: pending.replyTo?.id,
        attachmentId: pending.attachment?.id,
      );
      _ackTimers[pending.clientMsgId] = Timer(_ackTimeout, () => add(ConversationSendTimedOut(pending.clientMsgId)));
      return;
    }
    await _viaRest(pending, emit);
  }

  /// Stores [pending] over REST; idempotent on the server by its client id.
  Future<void> _viaRest(ChatMessage pending, Emitter<ConversationState> emit) async {
    try {
      final stored = await repository.sendMessage(
        _id,
        pending.body,
        pending.clientMsgId,
        replyTo: pending.replyTo?.id,
        attachmentId: pending.attachment?.id,
      );
      emit(state.copyWith(messages: _merge(state.messages, [stored])));
    } catch (e) {
      emit(state.copyWith(messages: _setDelivery(pending.clientMsgId, ChatDelivery.failed), response: _failure(e)));
    }
  }

  /// Sends a failed message again.
  Future<void> _onRetried(ConversationMessageRetried event, Emitter<ConversationState> emit) async {
    final pending = state.messages.where((m) => m.clientMsgId == event.clientMsgId).firstOrNull;
    if (pending == null) return;
    emit(state.copyWith(messages: _setDelivery(event.clientMsgId, ChatDelivery.sending)));
    await _viaRest(pending, emit);
  }

  /// The socket stayed silent: store the message over REST instead.
  Future<void> _onTimedOut(ConversationSendTimedOut event, Emitter<ConversationState> emit) async {
    _ackTimers.remove(event.clientMsgId);
    final pending = state.messages
        .where((m) => m.clientMsgId == event.clientMsgId && m.delivery == ChatDelivery.sending)
        .firstOrNull;
    if (pending != null) await _viaRest(pending, emit);
  }

  /// Applies one socket event.
  Future<void> _onSocket(ConversationSocketEvent event, Emitter<ConversationState> emit) async {
    switch (event.event) {
      case ChatLinkChanged(:final connected):
        emit(state.copyWith(connected: connected));
        if (connected && _linkedOnce && state.status.isSuccess) await _resync(emit);
        if (connected) _linkedOnce = true;
      case ChatMessageArrived(:final message):
        await _onArrived(message, emit);
      case ChatMessageUpdated(:final message):
        _applyUpdate(message, emit);
      case ChatPinChanged(:final message):
        _applyPin(message, emit);
      case ChatMessageAcked(:final clientMsgId, :final id):
        _ackTimers.remove(clientMsgId)?.cancel();
        emit(
          state.copyWith(
            messages: [
              for (final m in state.messages)
                m.clientMsgId == clientMsgId && m.delivery != ChatDelivery.sent
                    ? m.copyWith(id: id, delivery: ChatDelivery.sent)
                    : m,
            ],
          ),
        );
      case ChatReadReceipt(:final userId, :final messageId):
        if (userId != me.id && messageId > state.peerRead) emit(state.copyWith(peerRead: messageId));
      case ChatPresence(:final userId, :final online):
        emit(state.copyWith(online: online ? {...state.online, userId} : ({...state.online}..remove(userId))));
      case ChatPresenceSnapshot(:final online):
        emit(state.copyWith(online: online));
      case ChatRevoked():
        emit(state.copyWith(revoked: true, response: MessageErrorResponse(TrWords.chatRevoked.tr(), statusCode: 403)));
      case ChatSocketError(:final code):
        _onSocketError(code, emit);
    }
  }

  /// A server `error` frame: say so, and stop waiting for sends the server refused.
  /// Runs one change of an existing message and shows the stored result; a failure goes to the dialog.
  Future<void> _change(Emitter<ConversationState> emit, Future<ChatMessage> Function() action) async {
    try {
      _applyUpdate(await action(), emit);
    } catch (e) {
      emit(state.copyWith(response: _failure(e)));
    }
  }

  /// Replaces the message with the same id by [message] (keeping the known sender); also refreshes the pin banner.
  void _applyUpdate(ChatMessage message, Emitter<ConversationState> emit) {
    final sender = _senderOf(message.sender.id) ?? message.sender;
    final fresh = message.copyWith(sender: sender);
    final pinned = state.conversation?.pinned;
    emit(
      state.copyWith(
        messages: [for (final m in state.messages) m.id == fresh.id ? fresh : m],
        conversation: pinned != null && pinned.id == fresh.id
            ? (fresh.deleted
                  ? state.conversation!.copyWith(clearPinned: true)
                  : state.conversation!.copyWith(pinned: fresh))
            : null,
      ),
    );
  }

  /// Pins or unpins through the API and shows the stored conversation.
  Future<void> _onPinned(ConversationPinned event, Emitter<ConversationState> emit) async {
    try {
      final stored = await repository.pin(_id, event.id);
      emit(
        state.copyWith(
          conversation: state.conversation?.copyWith(pinned: stored.pinned, clearPinned: stored.pinned == null),
        ),
      );
    } catch (e) {
      emit(state.copyWith(response: _failure(e)));
    }
  }

  /// A live pin change from another member.
  void _applyPin(ChatMessage? message, Emitter<ConversationState> emit) {
    final sender = message == null ? null : _senderOf(message.sender.id);
    emit(
      state.copyWith(
        conversation: state.conversation?.copyWith(
          pinned: message == null ? null : message.copyWith(sender: sender ?? message.sender),
          clearPinned: message == null,
        ),
      ),
    );
  }

  void _onSocketError(String code, Emitter<ConversationState> emit) {
    final text = code == 'rate_limited' ? TrWords.chatRateLimited.tr() : TrWords.cLoadFailedDesc.tr();
    emit(
      state.copyWith(
        messages: [
          for (final m in state.messages)
            m.delivery == ChatDelivery.sending ? m.copyWith(delivery: ChatDelivery.failed) : m,
        ],
        response: MessageErrorResponse(text, statusCode: 429),
      ),
    );
  }

  /// A stored message arrived over the socket.
  Future<void> _onArrived(ChatMessage message, Emitter<ConversationState> emit) async {
    final known = _senderOf(message.sender.id);
    if (known == null) {
      // Unknown author (a member who joined meanwhile): the REST history carries full sender objects.
      await _resync(emit);
      return;
    }
    emit(state.copyWith(messages: _merge(state.messages, [message.copyWith(sender: known)])));
    if (message.sender.id != me.id) _markRead([message]);
  }

  /// Reloads the newest page and merges it (after a reconnect, or an unknown sender).
  Future<void> _resync(Emitter<ConversationState> emit) async {
    try {
      final page = await repository.getMessages(_id);
      emit(state.copyWith(messages: _merge(state.messages, page.messages)));
      _markRead(page.messages);
    } catch (_) {
      // Best effort: the socket keeps delivering new messages.
    }
  }

  /// Full reference of the participant [id] from what is already known, or null.
  UserRef? _senderOf(String id) {
    if (id == me.id) return me.ref;
    for (final m in state.conversation?.members ?? const <UserRef>[]) {
      if (m.id == id) return m;
    }
    for (final m in state.messages) {
      if (m.sender.id == id && m.sender.name.isNotEmpty) return m.sender;
    }
    return null;
  }

  /// Merges [incoming] into [current]: matching messages are replaced, new ones added; stored messages are
  /// ordered by id and unacknowledged ones stay last.
  List<ChatMessage> _merge(List<ChatMessage> current, List<ChatMessage> incoming) {
    final out = [...current];
    for (final m in incoming) {
      final i = out.indexWhere(m.isSame);
      if (i >= 0) {
        out[i] = m;
      } else {
        out.add(m);
      }
    }
    final stored = out.where((m) => m.delivery == ChatDelivery.sent).toList()..sort((a, b) => a.id.compareTo(b.id));
    return [...stored, ...out.where((m) => m.delivery != ChatDelivery.sent)];
  }

  /// Copy of the messages with the delivery of [clientMsgId] replaced.
  List<ChatMessage> _setDelivery(String clientMsgId, ChatDelivery delivery) => [
    for (final m in state.messages) m.clientMsgId == clientMsgId ? m.copyWith(delivery: delivery) : m,
  ];

  /// Moves the read marker to the newest message of others in [messages].
  void _markRead(List<ChatMessage> messages) {
    final newest = messages
        .where((m) => m.sender.id != me.id && m.id != 0)
        .map((m) => m.id)
        .fold(0, (a, b) => a > b ? a : b);
    if (newest == 0) return;
    if (_connection != null && state.connected) {
      _connection!.markRead(newest);
    } else {
      repository.markRead(_id, newest).ignore();
    }
  }

  @override
  Future<void> close() async {
    for (final t in _ackTimers.values) {
      t.cancel();
    }
    await _subscription?.cancel();
    await _connection?.close();
    return super.close();
  }
}
