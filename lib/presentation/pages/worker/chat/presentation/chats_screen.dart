import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/chat_kind.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/conversation_model.dart';
import 'package:eco_task/infrastructure/dto/models/user_ref.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import '../bloc/bloc.dart';

/// Chat tab: every conversation of the signed-in user with its last message
/// and unread badge, and a button that starts a new chat. Provides
/// [ChatsBloc] over the app-wide [ChatRepository].
class ChatsScreen extends StatelessWidget {
  /// Builds the chat tab.
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ChatsBloc(repository: RepositoryProvider.of<ChatRepository>(ctx))..add(const ChatsStarted()),
      child: const _ChatsView(),
    );
  }
}

/// Renders the conversation rows.
class _ChatsView extends StatelessWidget {
  /// Builds the list body.
  const _ChatsView();

  @override
  Widget build(BuildContext context) {
    final meId = RepositoryProvider.of<SessionRepository>(context).user.value!.user.id;
    return BlocConsumer<ChatsBloc, ChatsState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<ChatsBloc>();
        return ScreenShell(
          title: TrWords.chatTitle.tr(),
          big: true,
          showBack: false,
          padding: EdgeInsets.zero,
          actions: [
            IconButton(
              onPressed: () => context.push(Routes.chatNew.path).then((_) => bloc.add(const ChatsRefreshed())),
              icon: AppIcon(AppIcons.plus, color: theme.text),
            ),
          ],
          child: state.items.isEmpty && state.status.isLoading
              ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SmartLoading())
              : state.items.isEmpty
              ? (state.status.isError
                    ? EmptyView(
                        title: TrWords.cLoadFailed.tr(),
                        message: TrWords.cLoadFailedDesc.tr(),
                        icon: AppIcons.alert,
                        onRetry: () => bloc.add(const ChatsStarted()),
                      )
                    : EmptyView(title: TrWords.chatEmpty.tr(), message: TrWords.chatEmptyDesc.tr(), icon: AppIcons.msg))
              : RefreshList(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  gap: 10,
                  onRefresh: () async {
                    bloc.add(const ChatsRefreshed());
                    await bloc.stream.firstWhere((s) => !s.refreshing);
                  },
                  children: [
                    for (final c in state.items)
                      _ConversationRow(
                        conversation: c,
                        meId: meId,
                        onTap: () => context.push(Routes.chat.of(c.id)).then((_) => bloc.add(const ChatsRefreshed())),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

/// One row: avatar, name, last message preview, time and unread badge.
class _ConversationRow extends StatelessWidget {
  /// Conversation to show.
  final ConversationModel conversation;

  /// Id of the signed-in user, to pick the other person and label own previews.
  final String meId;

  /// Opens the conversation.
  final VoidCallback onTap;

  /// Builds the row.
  const _ConversationRow({required this.conversation, required this.meId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final last = conversation.last;
    final name = conversation.nameFor(meId);
    final preview = last == null
        ? ''
        : last.sender.id == meId
        ? TrWords.chatYouPrefix.tr(args: [last.body])
        : last.body;
    return CardWidget(
      onTap: onTap,
      child: Row(
        children: [
          conversation.kind == ChatKind.direct
              ? UserAvatar(
                  conversation.other(meId) ?? UserRef(id: conversation.id, name: name),
                  size: 44.w,
                )
              : _KindTile(kind: conversation.kind),
          12.w.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.cardTitle),
                    ),
                    if (last != null) Text(DateFormatter.ago(last.at), style: theme.cardSubtitle),
                  ],
                ),
                4.h.height,
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.cardSubtitle.copyWith(
                          color: conversation.unread > 0 ? theme.text : theme.grayText,
                          fontWeight: conversation.unread > 0 ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (conversation.unread > 0) ...[
                      8.w.width,
                      Badge(label: Text('${conversation.unread}'), backgroundColor: theme.primary),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Round tile that stands in for the avatar of a group or task chat.
class _KindTile extends StatelessWidget {
  /// Kind that picks the glyph.
  final ChatKind kind;

  /// Builds the tile.
  const _KindTile({required this.kind});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(color: theme.primaryTint, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: AppIcon(kind == ChatKind.task ? AppIcons.tasks : AppIcons.users, color: theme.primaryDark),
    );
  }
}
