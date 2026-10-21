import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/notification_kind.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/notification_model.dart';
import 'package:eco_task/infrastructure/repository/notifications_repository.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/infrastructure/repository/settings_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/filter_pill.dart';
import 'package:eco_task/presentation/public/widgets/notice_banner.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import '../bloc/bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';

/// The inbox: filter tabs, entries grouped by day, mark-all-read. Shown as a
/// tab ([pushed] false) or as a pushed screen with a back button. Provides
/// [NotificationsBloc] over the app-wide [NotificationsRepository].
class NotificationsScreen extends StatelessWidget {
  /// True when opened from the dashboard bell instead of a bottom tab.
  final bool pushed;

  /// Builds the inbox.
  const NotificationsScreen({super.key, this.pushed = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          NotificationsBloc(repository: RepositoryProvider.of<NotificationsRepository>(ctx))
            ..add(const NotificationsStarted()),
      child: _NotificationsView(pushed: pushed),
    );
  }
}

/// Renders the permission notice, the filter strip and the day groups.
class _NotificationsView extends StatelessWidget {
  /// True when the screen was pushed rather than shown as a tab.
  final bool pushed;

  /// Builds the inbox body.
  const _NotificationsView({required this.pushed});

  @override
  Widget build(BuildContext context) {
    final role = RepositoryProvider.of<SessionRepository>(context).role;
    final settings = RepositoryProvider.of<SettingsRepository>(context).settings;
    final unread = RepositoryProvider.of<NotificationsRepository>(context).unread;
    return BlocConsumer<NotificationsBloc, NotificationsState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<NotificationsBloc>();
        // Filter tabs: bosses get the full set, everyone else all/unread only.
        final groups = role?.isBoss == true
            ? NotificationGroup.values
            : const [NotificationGroup.all, NotificationGroup.unread];
        // Entries grouped by the day label, newest first.
        final byDay = <String, List<NotificationModel>>{};
        for (final n in state.items) {
          final diff = DateFormatter.daysTo(n.at);
          (byDay[diff == 0
                      ? TrWords.cToday.tr()
                      : diff == -1
                      ? TrWords.cYesterday.tr()
                      : DateFormatter.day(n.at)] ??=
                  [])
              .add(n);
        }
        return ScreenShell(
          title: TrWords.ntfTitle.tr(),
          big: !pushed,
          showBack: pushed,
          padding: EdgeInsets.zero,
          actions: [
            Btn.ghost(text: TrWords.ntfMarkAll.tr(), onPressed: () => bloc.add(const NotificationsMarkedRead())),
          ],
          child: Column(
            children: [
              ValueListenableBuilder<AppSettings>(
                valueListenable: settings,
                builder: (context, s, _) => s.permOn
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                        child: NoticeBanner(
                          text: TrWords.ntfOff.tr(),
                          action: GestureDetector(
                            onTap: () => context.push(Routes.settingsNotifications.path),
                            child: Padding(
                              padding: EdgeInsets.only(top: 6.h),
                              child: Text(
                                TrWords.ntfOpenSettings.tr(),
                                style: theme.badgeText.copyWith(color: theme.primary),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              SizedBox(
                height: 36.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  children: [
                    for (final group in groups)
                      Padding(
                        padding: 8.w.right,
                        child: FilterPill(
                          label: switch (group) {
                            NotificationGroup.all => TrWords.cAll.tr(),
                            NotificationGroup.unread => TrWords.ntfUnread.tr(args: ['${unread.value}']),
                            NotificationGroup.review => TrWords.ntfReview.tr(),
                            NotificationGroup.deadlines => TrWords.ntfDeadlines.tr(),
                            NotificationGroup.expenses => TrWords.ntfExpenses.tr(),
                          },
                          selected: state.group == group,
                          onTap: () => bloc.add(NotificationsGroupChanged(group)),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: state.items.isEmpty && state.status.isLoading
                      ? const SmartLoading(count: 4)
                      : RefreshList(
                          onRefresh: () async {
                            bloc.add(const NotificationsRefreshed());
                            await bloc.stream.firstWhere((s) => !s.refreshing);
                          },
                          onLoadMore: () => bloc.add(const NotificationsMoreRequested()),
                          isLoadingMore: state.isLoadingMore,
                          placeholder: state.status.isError
                              ? EmptyView(
                                  title: TrWords.cLoadFailed.tr(),
                                  message: TrWords.cLoadFailedDesc.tr(),
                                  icon: AppIcons.alert,
                                  onRetry: () => bloc.add(const NotificationsStarted()),
                                )
                              : EmptyView(
                                  title: TrWords.ntfEmpty.tr(),
                                  message: TrWords.ntfEmptyDesc.tr(),
                                  icon: AppIcons.bell,
                                ),
                          children: [
                            for (final entry in byDay.entries)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.key, style: theme.sectionLabel),
                                  8.h.height,
                                  CardWidget(
                                    padding: EdgeInsets.zero,
                                    child: Column(
                                      children: [
                                        for (final (i, n) in entry.value.indexed)
                                          InkWell(
                                            onTap: () {
                                              bloc.add(NotificationsMarkedRead(id: n.id));
                                              if (role?.isBoss == true && n.kind == NotificationKind.review)
                                                context.push(Routes.review.path);
                                              if (role?.isBoss == true && n.kind == NotificationKind.expense)
                                                context.push(Routes.expenses.path);
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(14.w),
                                              decoration: BoxDecoration(
                                                border: i == 0 ? null : Border(top: BorderSide(color: theme.line)),
                                              ),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  AppIcon.tile(n.kind.icon, tone: n.kind.tone),
                                                  12.w.width,
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          n.kind.title(n.titleArgs),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: theme.textStyle.copyWith(
                                                            fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                                                          ),
                                                        ),
                                                        2.h.height,
                                                        Text(
                                                          n.kind.body(n.bodyArgs),
                                                          maxLines: 3,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: theme.cardSubtitle.copyWith(
                                                            color: theme.textSecondary,
                                                            height: 1.35,
                                                          ),
                                                        ),
                                                        4.h.height,
                                                        Text(DateFormatter.ago(n.at), style: theme.cardSubtitle),
                                                      ],
                                                    ),
                                                  ),
                                                  if (!n.isRead)
                                                    Container(
                                                      width: 8.w,
                                                      height: 8.w,
                                                      margin: EdgeInsets.only(top: 6.h, left: 8.w),
                                                      decoration: BoxDecoration(
                                                        color: StatusTone.primary.color,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
