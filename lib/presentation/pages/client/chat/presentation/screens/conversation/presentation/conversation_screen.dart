import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/call_kind.dart';
import 'package:eco_task/domain/common/enums/chat_kind.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/infrastructure/dto/models/chat_message.dart';
import 'package:eco_task/presentation/public/dialogs/confirm_dialog.dart';
import 'package:eco_task/presentation/public/toast/toast_helpers.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/helpers/voice_recorder.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/infrastructure/repository/files_repository.dart';
import 'package:eco_task/helpers/media_picker.dart';
import 'package:eco_task/presentation/public/dialogs/pick_source_sheet.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/header_action.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import '../bloc/bloc.dart';
import 'dialogs/message_actions_sheet.dart';
import 'parts/message_bubble.dart';
import 'widgets/reply_quote.dart';
import 'widgets/pinned_banner.dart';

/// One conversation: the message thread (newest at the bottom), a banner while
/// the live link is down and the message input. Opened by conversation id, or
/// by task id for a task's discussion. Provides [ConversationBloc] over the
/// app-wide [ChatRepository].
class ConversationScreen extends StatelessWidget {
  /// Conversation to open; null when [taskId] is given.
  final String? conversationId;

  /// Task whose discussion to open; null when [conversationId] is given.
  final String? taskId;

  /// Builds the conversation screen.
  const ConversationScreen({super.key, this.conversationId, this.taskId})
    : assert((conversationId == null) != (taskId == null), 'pass exactly one of conversationId, taskId');

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ConversationBloc(
        repository: RepositoryProvider.of<ChatRepository>(ctx),
        files: RepositoryProvider.of<FilesRepository>(ctx),
        me: RepositoryProvider.of<SessionRepository>(ctx).user.value!.user,
        conversationId: conversationId,
        taskId: taskId,
      )..add(const ConversationStarted()),
      child: const _ConversationView(),
    );
  }
}

/// Renders the thread and the input.
class _ConversationView extends StatefulWidget {
  /// Builds the body.
  const _ConversationView();

  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

/// Owns the input controller.
class _ConversationViewState extends State<_ConversationView> {
  /// Controller of the message field.
  final _input = TextEditingController();

  /// The message being edited; null while composing a new one.
  ChatMessage? _editing;

  /// Records voice notes while the mic button is held.
  final _recorder = VoiceRecorder();

  /// True when the empty-input button records video circles instead of voice notes.
  bool _circleMode = false;

  /// Seconds recorded so far; null while not recording.
  int? _recordSeconds;

  /// True while the finger is slid away far enough to cancel the recording.
  bool _cancelling = false;

  /// Ticks the recording clock.
  Timer? _clock;

  /// True while the input holds text, which swaps the mic button for "send".
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(() {
      final has = _input.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _recorder.dispose();
    _input.dispose();
    super.dispose();
  }

  /// Sends the typed text, if any.
  void _send(ConversationBloc bloc) {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final editing = _editing;
    if (editing == null) {
      bloc.add(ConversationMessageSent(text));
    } else {
      if (text != editing.body) bloc.add(ConversationMessageEdited(editing.id, text));
      setState(() => _editing = null);
    }
    _input.clear();
  }

  /// Picks photos or a document and sends each as a message.
  Future<void> _attach(ConversationBloc bloc) async {
    for (final f in await PickSourceSheet.show(context)) {
      bloc.add(ConversationFileSent(f));
    }
  }

  /// Starts a voice note, or records a video circle with the camera, depending on the mode.
  Future<void> _startRecording(ConversationBloc bloc) async {
    if (_circleMode) {
      final video = await MediaPicker.videoCircle();
      if (video != null) bloc.add(ConversationFileSent(video));
      return;
    }
    if (!await _recorder.start()) {
      if (mounted) showScreenResponse(context, MessageErrorResponse(TrWords.flMicDenied.tr()));
      return;
    }
    setState(() {
      _recordSeconds = 0;
      _cancelling = false;
    });
    _clock = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _recordSeconds = (_recordSeconds ?? 0) + 1),
    );
  }

  /// Ends the voice note: sends it, or drops it when the finger was slid away.
  Future<void> _stopRecording(ConversationBloc bloc) async {
    if (_recordSeconds == null) return;
    _clock?.cancel();
    final discard = _cancelling;
    setState(() => _recordSeconds = null);
    final file = await _recorder.stop(discard: discard);
    if (file != null) bloc.add(ConversationFileSent(file));
  }

  /// Opens the actions sheet for [m] and runs the choice.
  Future<void> _actions(BuildContext context, ConversationBloc bloc, ChatMessage m, String meId, bool pinned) async {
    final isStaff = RepositoryProvider.of<SessionRepository>(context).user.value!.user.role.isBoss;
    final mineEmoji = m.reactions.where((r) => r.userIds.contains(meId)).firstOrNull?.emoji;
    final choice = await MessageActionsSheet.show(
      context,
      preview: m.body,
      mine: mineEmoji,
      canEdit: m.sender.id == meId,
      canDelete: m.sender.id == meId || isStaff,
      pinned: pinned,
    );
    if (choice == null || !context.mounted) return;
    switch (choice.action) {
      case MessageAction.reply:
        bloc.add(ConversationReplyChanged(m));
      case MessageAction.react:
        // Tapping the emoji already chosen takes it back.
        bloc.add(ConversationReacted(m.id, mineEmoji == choice.emoji ? null : choice.emoji));
      case MessageAction.copy:
        showTopToast(
          context,
          icon: AppIcons.check,
          tone: StatusTone.primary,
          title: TrWords.ch2Copied.tr(),
          message: '',
        );
      case MessageAction.edit:
        setState(() => _editing = m);
        _input.text = m.body;
      case MessageAction.pin:
        bloc.add(ConversationPinned(pinned ? null : m.id));
      case MessageAction.delete:
        await ConfirmDialog.show(
          context,
          icon: AppIcons.trash,
          title: TrWords.ch2DelT.tr(),
          message: TrWords.ch2DelD.tr(),
          confirmText: TrWords.ch2Delete.tr(),
          onConfirm: () async => bloc.add(ConversationMessageDeleted(m.id)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meId = RepositoryProvider.of<SessionRepository>(context).user.value!.user.id;
    return BlocConsumer<ConversationBloc, ConversationState>(
      listenWhen: (prev, cur) => cur.response != null || (cur.revoked && !prev.revoked),
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        if (state.revoked && context.canPop()) context.pop();
      },
      builder: (context, state) {
        final bloc = context.read<ConversationBloc>();
        final conversation = state.conversation;
        if (conversation == null) {
          return Scaffold(
            backgroundColor: theme.background,
            body: Column(
              children: [
                InnerBar(title: TrWords.chatTitle.tr()),
                Expanded(
                  child: state.status.isError
                      ? EmptyView(
                          title: TrWords.cLoadFailed.tr(),
                          message: TrWords.cLoadFailedDesc.tr(),
                          icon: AppIcons.alert,
                          onRetry: () => bloc.add(const ConversationStarted()),
                        )
                      : const Padding(padding: EdgeInsets.all(16), child: SmartLoading(count: 3)),
                ),
              ],
            ),
          );
        }
        final other = conversation.other(meId);
        final subtitle = !state.connected
            ? TrWords.chatConnecting.tr()
            : other != null
            ? (state.online.contains(other.id) ? TrWords.chatOnline.tr() : null)
            : conversation.members.isEmpty
            ? null
            : TrWords.chatMembersN.tr(args: ['${conversation.members.length}']);
        final grouped = conversation.kind != ChatKind.direct;
        // Messages are listed newest-first because the list is reversed (it starts at the bottom).
        final rows = state.messages.reversed.toList();
        final title = conversation.kind == ChatKind.task && conversation.title.isEmpty
            ? TrWords.chatTaskChat.tr()
            : conversation.nameFor(meId);
        final online = other != null && state.connected && state.online.contains(other.id);
        return Scaffold(
          backgroundColor: theme.background,
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
              InnerBar(
                actions: [
                  if (conversation.kind != ChatKind.task)
                    HeaderAction(
                      icon: AppIcons.handset,
                      onTap: () => context.push(
                        '${Routes.call.of('new')}?conversation=${conversation.id}&kind=${CallKind.audio.apiName}',
                      ),
                    ),
                ],
                center: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: conversation.kind == ChatKind.task
                      ? null
                      : () => context.push(Routes.chatInfo.of(conversation.id)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textStyle.copyWith(fontSize: 16.sp, height: 20 / 16, fontWeight: FontWeight.w600),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.cardSubtitle.copyWith(
                            fontSize: 12.sp,
                            color: online ? theme.primary : theme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (conversation.pinned != null)
                PinnedBanner(text: conversation.pinned!.body, onClear: () => bloc.add(const ConversationPinned(null))),
              Expanded(
                child: rows.isEmpty
                    ? EmptyView(title: TrWords.chatNoMessages.tr(), icon: AppIcons.msg)
                    : ListView.builder(
                        reverse: true,
                        padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
                        // One extra row at the top (the end of a reversed list) for the "older messages" button.
                        itemCount: rows.length + (state.hasMore ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i == rows.length) {
                            return Center(
                              child: TextButton(
                                onPressed: state.loadingOlder
                                    ? null
                                    : () => bloc.add(const ConversationOlderRequested()),
                                child: Text(TrWords.chatOlder.tr()),
                              ),
                            );
                          }
                          final m = rows[i];
                          final mine = m.sender.id == meId;
                          // The list is reversed, so a day's caption goes above its oldest message.
                          final firstOfDay = i == rows.length - 1 || !DateFormatter.sameDay(rows[i + 1].at, m.at);
                          return Column(
                            children: [
                              if (firstOfDay) DayPill(m.at),
                              MessageBubble(
                                message: m,
                                mine: mine,
                                showAuthor: grouped,
                                read: mine && m.id != 0 && m.id <= state.peerRead,
                                meId: meId,
                                onRetry: () => bloc.add(ConversationMessageRetried(m.clientMsgId)),
                                onReact: m.id == 0
                                    ? null
                                    : (e) => bloc.add(
                                        ConversationReacted(
                                          m.id,
                                          m.reactions.any((r) => r.emoji == e && r.userIds.contains(meId)) ? null : e,
                                        ),
                                      ),
                                onLongPress: m.id == 0 || m.deleted
                                    ? null
                                    : () => _actions(context, bloc, m, meId, conversation.pinned?.id == m.id),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 8.h + ScreenSize.bottomInset(context)),
                decoration: BoxDecoration(
                  color: theme.cardColor.withValues(alpha: 0.92),
                  border: Border(top: BorderSide(color: theme.line, width: 0.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!state.connected && state.status.isSuccess)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Text(TrWords.chatOffline.tr(), style: theme.cardSubtitle.copyWith(color: theme.warn)),
                      ),
                    if (state.replyingTo != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: ReplyQuote(
                          reply: ChatReply(
                            id: state.replyingTo!.id,
                            senderName: state.replyingTo!.sender.name,
                            body: state.replyingTo!.body,
                            attachmentKind: state.replyingTo!.attachment?.kind,
                          ),
                          color: theme.primary,
                          onClose: () => bloc.add(const ConversationReplyChanged(null)),
                        ),
                      ),
                    if (state.uploading)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: LinearProgressIndicator(minHeight: 2, color: theme.primary, backgroundColor: theme.line),
                      ),
                    if (_editing != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Row(
                          children: [
                            AppIcon(AppIcons.edit, size: 16.sp, color: theme.primary),
                            8.w.width,
                            Expanded(
                              child: Text(
                                TrWords.ch2Editing.tr(),
                                style: theme.textStyle.copyWith(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: theme.primary,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() {
                                _editing = null;
                                _input.clear();
                              }),
                              child: AppIcon(AppIcons.x, size: 18.sp, color: theme.grayText),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_editing == null && _recordSeconds == null) ...[
                          GestureDetector(
                            onTap: () => _attach(bloc),
                            child: SizedBox(
                              width: 40.w,
                              height: 40.w,
                              child: Center(
                                child: AppIcon(AppIcons.clip, size: 24.sp, color: theme.grayText),
                              ),
                            ),
                          ),
                        ],
                        if (_recordSeconds != null)
                          Expanded(
                            child: Container(
                              height: 40.h,
                              padding: EdgeInsets.symmetric(horizontal: 14.w),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: 20.circular,
                                border: Border.all(color: _cancelling ? theme.red : theme.line),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10.w,
                                    height: 10.w,
                                    decoration: BoxDecoration(color: theme.red, shape: BoxShape.circle),
                                  ),
                                  8.w.width,
                                  Text(
                                    '${_recordSeconds! ~/ 60}:${(_recordSeconds! % 60).toString().padLeft(2, '0')}',
                                    style: theme.textStyle,
                                  ),
                                  const Spacer(),
                                  Text(
                                    TrWords.flSlideCancel.tr(),
                                    style: theme.cardSubtitle.copyWith(color: _cancelling ? theme.red : theme.grayText),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: Container(
                              constraints: BoxConstraints(minHeight: 40.h),
                              padding: EdgeInsets.symmetric(horizontal: 14.w),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: 20.circular,
                                border: Border.all(color: theme.line),
                              ),
                              child: TextField(
                                controller: _input,
                                minLines: 1,
                                maxLines: 5,
                                cursorColor: theme.primary,
                                style: theme.textStyle.copyWith(fontWeight: FontWeight.w400),
                                decoration: InputDecoration(
                                  hintText: TrWords.chatWrite.tr(),
                                  hintStyle: theme.textStyle.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: theme.grayText,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                        6.w.width,
                        GestureDetector(
                          onTap: _hasText || _editing != null
                              ? () => _send(bloc)
                              : () => setState(() => _circleMode = !_circleMode),
                          onLongPressStart: _hasText || _editing != null ? null : (_) => _startRecording(bloc),
                          onLongPressMoveUpdate: (d) {
                            final cancel = d.offsetFromOrigin.dx < -80;
                            if (_recordSeconds != null && cancel != _cancelling) setState(() => _cancelling = cancel);
                          },
                          onLongPressEnd: (_) => _stopRecording(bloc),
                          child: Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              color: _recordSeconds != null && !_cancelling ? theme.red : theme.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: AppIcon(
                              _hasText || _editing != null
                                  ? AppIcons.send
                                  : (_circleMode ? AppIcons.video : AppIcons.mic),
                              size: 20.sp,
                              color: theme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
