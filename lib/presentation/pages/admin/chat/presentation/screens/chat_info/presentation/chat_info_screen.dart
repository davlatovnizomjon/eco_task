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
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';
import 'package:eco_task/presentation/public/dialogs/confirm_dialog.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/detail_row.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/role_pill.dart';
import 'package:eco_task/presentation/public/widgets/setting_row.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/auth_image.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/phone_formatter.dart';

import '../bloc/bloc.dart';

/// Info page of a conversation: for a direct chat the other person (avatar, role, phone, active tasks, "message" and
/// mute buttons); for a group the title, the member list with roles, "add member" and "leave group". Provides
/// [ChatInfoBloc].
class ChatInfoScreen extends StatelessWidget {
  /// Id of the conversation described.
  final String conversationId;

  /// Builds the page.
  const ChatInfoScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ChatInfoBloc(
        repository: RepositoryProvider.of<ChatRepository>(ctx),
        team: RepositoryProvider.of<TeamRepository>(ctx),
        tasks: RepositoryProvider.of<TasksRepository>(ctx),
        meId: RepositoryProvider.of<SessionRepository>(ctx).user.value!.user.id,
        conversationId: conversationId,
      )..add(const ChatInfoStarted()),
      child: const _ChatInfoView(),
    );
  }
}

/// Renders the page for the current state.
class _ChatInfoView extends StatelessWidget {
  /// Builds the view.
  const _ChatInfoView();

  /// One of the two round action buttons under the header: a tinted square with a glyph and a caption.
  Widget _action(String icon, String label, VoidCallback onTap, {bool active = false}) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64.h,
        decoration: BoxDecoration(
          color: active ? theme.primaryTint : theme.cardColor,
          borderRadius: 14.circular,
          border: Border.all(color: active ? theme.primary : theme.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(icon, size: 22.sp, color: theme.primary),
            4.h.height,
            Text(
              label,
              style: theme.textStyle.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w600, color: theme.primary),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    /// Id of the signed-in person.
    final meId = RepositoryProvider.of<SessionRepository>(context).user.value!.user.id;
    return BlocConsumer<ChatInfoBloc, ChatInfoState>(
      listenWhen: (prev, cur) => cur.response != null || cur.left,
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        // Leaving a group closes the info page and the room under it.
        if (state.left) context.go(Routes.home.path);
      },
      builder: (context, state) {
        /// Bloc of this page.
        final bloc = context.read<ChatInfoBloc>();

        /// Loaded conversation; null while loading or after a failure.
        final c = state.conversation;
        if (c == null) {
          return Scaffold(
            backgroundColor: theme.background,
            body: Column(
              children: [
                const InnerBar(),
                Expanded(
                  child: state.status == ScreenStatus.error
                      ? EmptyView.tile(
                          icon: AppIcons.wifioff,
                          tone: StatusTone.warn,
                          title: TrWords.cLoadFailed.tr(),
                          message: TrWords.cLoadFailedDesc.tr(),
                          onRetry: () => bloc.add(const ChatInfoStarted()),
                        )
                      : const Padding(padding: EdgeInsets.all(16), child: SmartLoading(count: 2)),
                ),
              ],
            ),
          );
        }

        /// True for a group, false for a direct chat.
        final group = c.kind == ChatKind.group;
        final other = c.other(meId);
        return Scaffold(
          backgroundColor: theme.background,
          body: Column(
            children: [
              InnerBar(
                actions: [
                  if (group && RepositoryProvider.of<SessionRepository>(context).user.value!.user.role.isBoss)
                    IconButton(
                      onPressed: () =>
                          context.push(Routes.groupEdit.of(c.id)).then((_) => bloc.add(const ChatInfoStarted())),
                      icon: AppIcon(AppIcons.edit, size: 22.sp, color: theme.primary),
                    ),
                ],
              ),
              Expanded(
                child: RefreshList(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h + MediaQuery.of(context).padding.bottom),
                  gap: 16,
                  onRefresh: () async {
                    bloc.add(const ChatInfoStarted());
                    await bloc.stream.firstWhere((s) => s.status != ScreenStatus.loading);
                  },
                  children: [
                    _header(c, meId, group),
                    Row(
                      children: [
                        _action(AppIcons.msg, TrWords.ch2Write.tr(), () => context.pop()),
                        10.w.width,
                        _action(
                          AppIcons.bell,
                          (c.muted ? TrWords.ch2Unmute : TrWords.ch2Mute).tr(),
                          () => bloc.add(const ChatInfoMuteToggled()),
                          active: c.muted,
                        ),
                      ],
                    ),
                    if (c.muted)
                      Row(
                        children: [
                          AppIcon(AppIcons.bell, size: 16.sp, color: theme.grayText),
                          8.w.width,
                          Text(TrWords.ch2MutedNote.tr(), style: theme.cardSubtitle),
                        ],
                      ),
                    if (!group && state.person != null)
                      CardWidget(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                        decoration: theme.panelDecor,
                        child: Column(
                          children: [
                            DetailRow(
                              first: true,
                              icon: AppIcons.phone,
                              label: TrWords.ch2Phone.tr(),
                              value: PhoneFormatter.display(state.person!.phone),
                            ),
                            DetailRow(
                              icon: AppIcons.user,
                              label: TrWords.ch2Role.tr(),
                              value: state.person!.role.title,
                            ),
                            if (state.person!.role == UserRole.worker || state.person!.role == UserRole.assistant)
                              DetailRow(
                                icon: AppIcons.tasks,
                                label: TrWords.ch2ActiveTasks.tr(),
                                value: TrWords.ch2NTasks.tr(args: ['${state.activeTasks}']),
                              ),
                          ],
                        ),
                      ),
                    if (group) ...[
                      Text(TrWords.ch2Members.tr(), style: theme.fieldLabel),
                      CardWidget(
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        decoration: theme.panelDecor,
                        child: Column(
                          children: [
                            for (final (i, m) in c.members.indexed)
                              Container(
                                constraints: BoxConstraints(minHeight: 60.h),
                                decoration: BoxDecoration(
                                  border: i == 0 ? null : Border(top: BorderSide(color: theme.line)),
                                ),
                                child: Row(
                                  children: [
                                    UserAvatar(m, size: 40.w),
                                    12.w.width,
                                    Expanded(
                                      child: Text(
                                        m.id == meId ? '${m.name} (${TrWords.ch2You.tr()})' : m.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textStyle,
                                      ),
                                    ),
                                    if (m.role != null) RolePill(m.role!),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      CardWidget(
                        padding: EdgeInsets.zero,
                        decoration: theme.panelDecor,
                        child: SettingRow(
                          first: true,
                          icon: AppIcons.logout,
                          tone: StatusTone.error,
                          title: TrWords.ch2Leave.tr(),
                          onTap: () => ConfirmDialog.show(
                            context,
                            icon: AppIcons.logout,
                            title: TrWords.ch2LeaveT.tr(),
                            message: TrWords.ch2LeaveD.tr(args: [c.title]),
                            confirmText: TrWords.cLogout.tr(),
                            onConfirm: () async {
                              bloc.add(const ChatInfoLeft());
                              await bloc.stream.firstWhere((s) => !s.busy);
                            },
                          ),
                        ),
                      ),
                    ],
                    if (!group && other == null) const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Avatar (or group tile), name and the one-line status under it.
  Widget _header(ConversationModel c, String meId, bool group) {
    /// The other person of a direct chat.
    final other = c.other(meId);
    return Column(
      children: [
        if (group && c.avatar != null)
          SizedBox(
            width: 96.w,
            height: 96.w,
            child: AuthImage(c.avatar!.id, radius: 48.w),
          )
        else if (group)
          AppIcon.tile(AppIcons.users, tone: StatusTone.primary, size: 96)
        else if (other != null)
          UserAvatar(other, size: 96.w),
        12.h.height,
        Text(
          c.nameFor(meId),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textStyle.copyWith(fontSize: 22.sp, height: 28 / 22, fontWeight: FontWeight.w700),
        ),
        if (group) ...[
          4.h.height,
          Text(TrWords.chatMembersN.tr(args: ['${c.members.length}']), style: theme.cardSubtitle),
        ],
      ],
    );
  }
}
