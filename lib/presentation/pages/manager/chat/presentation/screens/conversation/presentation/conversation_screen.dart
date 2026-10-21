import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/chat_kind.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';

import '../bloc/bloc.dart';
import 'parts/message_bubble.dart';

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

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  /// Sends the typed text, if any.
  void _send(ConversationBloc bloc) {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    bloc.add(ConversationMessageSent(text));
    _input.clear();
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
          return ScreenShell(
            title: TrWords.chatTitle.tr(),
            child: state.status.isError
                ? EmptyView(
                    title: TrWords.cLoadFailed.tr(),
                    message: TrWords.cLoadFailedDesc.tr(),
                    icon: AppIcons.alert,
                    onRetry: () => bloc.add(const ConversationStarted()),
                  )
                : const SmartLoading(count: 3),
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
        return ScreenShell(
          // Non-"big" shells show no subtitle, so the status rides along in the title.
          title: [
            conversation.kind == ChatKind.task && conversation.title.isEmpty
                ? TrWords.chatTaskChat.tr()
                : conversation.nameFor(meId),
            ?subtitle,
          ].join(' · '),
          padding: EdgeInsets.zero,
          resizeToAvoidBottomInset: true,
          bottomBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!state.connected && state.status.isSuccess)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Text(TrWords.chatOffline.tr(), style: theme.cardSubtitle.copyWith(color: theme.warn)),
                ),
              InputBox(
                controller: _input,
                hint: TrWords.chatWrite.tr(),
                rightWidget: GestureDetector(
                  onTap: () => _send(bloc),
                  child: AppIcon(AppIcons.send, color: theme.primary),
                ),
              ),
            ],
          ),
          child: rows.isEmpty
              ? EmptyView(title: TrWords.chatNoMessages.tr(), icon: AppIcons.msg)
              : ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                  // One extra row at the top (the end of a reversed list) for the "older messages" button.
                  itemCount: rows.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == rows.length) {
                      return Center(
                        child: TextButton(
                          onPressed: state.loadingOlder ? null : () => bloc.add(const ConversationOlderRequested()),
                          child: Text(TrWords.chatOlder.tr()),
                        ),
                      );
                    }
                    final m = rows[i];
                    final mine = m.sender.id == meId;
                    return MessageBubble(
                      message: m,
                      mine: mine,
                      showAuthor: grouped,
                      read: mine && m.id != 0 && m.id <= state.peerRead,
                      onRetry: () => bloc.add(ConversationMessageRetried(m.clientMsgId)),
                    );
                  },
                ),
        );
      },
    );
  }
}
