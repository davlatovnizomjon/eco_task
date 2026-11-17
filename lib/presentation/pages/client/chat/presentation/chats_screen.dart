import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/chat_kind.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/conversation_model.dart';
import 'package:eco_task/infrastructure/dto/models/user_ref.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/chat_row.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/floating_tab_bar.dart';
import 'package:eco_task/presentation/public/widgets/header_action.dart';
import 'package:eco_task/presentation/public/widgets/large_title_header.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/underline_tabs.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/tone_circle.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import '../bloc/bloc.dart';

/// Client chat tab: a large title and the client's conversations (mostly with the dispatcher and the assigned masters);
/// there is no "new chat" button, the company starts the conversations. Provides [ChatsBloc].
class ChatsScreen extends StatelessWidget {
  /// Builds the tab.
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ChatsBloc(repository: RepositoryProvider.of<ChatRepository>(ctx))..add(const ChatsStarted()),
      child: const _ChatsView(),
    );
  }
}

/// Renders the header, the switch and the two sections.
class _ChatsView extends StatefulWidget {
  /// Builds the view.
  const _ChatsView();

  @override
  State<_ChatsView> createState() => _ChatsViewState();
}

/// Holds the selected switch segment.
class _ChatsViewState extends State<_ChatsView> {
  @override
  Widget build(BuildContext context) {
    final meId = RepositoryProvider.of<SessionRepository>(context).user.value!.user.id;
    return BlocConsumer<ChatsBloc, ChatsState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<ChatsBloc>();
        final items = state.items;
        void refresh(Object? _) => bloc.add(const ChatsRefreshed());
        return Column(
          children: [
            LargeTitleHeader(title: TrWords.chatTitle.tr()),
            Expanded(
              child: state.items.isEmpty && state.status.isLoading
                  ? const Padding(padding: EdgeInsets.all(16), child: SmartLoading())
                  : state.items.isEmpty
                  ? (state.status.isError
                        ? EmptyView(
                            title: TrWords.cLoadFailed.tr(),
                            message: TrWords.cLoadFailedDesc.tr(),
                            icon: AppIcons.alert,
                            onRetry: () => bloc.add(const ChatsStarted()),
                          )
                        : EmptyView(
                            title: TrWords.clChatEmptyT.tr(),
                            message: TrWords.clChatEmptyD.tr(),
                            icon: AppIcons.msg,
                          ))
                  : RefreshList(
                      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, FloatingTabBar.inset(context)),
                      gap: 0,
                      onRefresh: () async {
                        bloc.add(const ChatsRefreshed());
                        await bloc.stream.firstWhere((s) => !s.refreshing);
                      },
                      children: [
                        for (final (i, c) in items.indexed) _row(context, c, meId, first: i == 0, onDone: refresh),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  /// One conversation row for [c] viewed by [meId].
  Widget _row(
    BuildContext context,
    ConversationModel c,
    String meId, {
    required bool first,
    required void Function(Object?) onDone,
  }) {
    final last = c.last;
    final other = c.other(meId);
    final mine = last != null && last.sender.id == meId;
    final preview = last == null
        ? ''
        : c.kind != ChatKind.direct && !mine
        ? '${last.sender.firstName}: ${last.body}'
        : last.body;
    return ChatRow(
      first: first,
      avatar: c.kind == ChatKind.direct
          ? UserAvatar(
              other ?? UserRef(id: c.id, name: c.nameFor(meId)),
              size: 48.w,
            )
          : ToneCircle(
              c.kind == ChatKind.task ? AppIcons.tasks : AppIcons.users,
              tone: c.kind == ChatKind.task ? StatusTone.info : StatusTone.primary,
              size: 48.w,
            ),
      name: c.nameFor(meId),
      badge: other?.role == null || other!.role == UserRole.client
          ? null
          : Container(
              height: 20.h,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (other.role == UserRole.worker ? StatusTone.info : StatusTone.neutral).bgColor,
                borderRadius: 10.circular,
              ),
              child: Text(
                (other.role == UserRole.worker ? TrWords.clMaster : TrWords.clDispatcher).tr(),
                style: theme.badgeText.copyWith(
                  fontSize: 11.sp,
                  color: (other.role == UserRole.worker ? StatusTone.info : StatusTone.neutral).color,
                ),
              ),
            ),
      time: last == null ? '' : _time(last.at),
      message: preview,
      unread: c.unread,
      receipt: mine ? AppIcon(AppIcons.check, size: 16.sp, color: theme.info) : null,
      onTap: () => context.push(Routes.chat.of(c.id)).then(onDone),
    );
  }

  /// `10:42` for today, `Kecha` for yesterday, otherwise a short date.
  static String _time(DateTime at) {
    final diff = DateFormatter.daysTo(at);
    if (diff == 0) return DateFormatter.time(at);
    if (diff == -1) return TrWords.cYesterday.tr();
    return DateFormatter.dayShort(at);
  }
}
