import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/app_user.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/header_action.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/list_row.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/search_field.dart';
import 'package:eco_task/presentation/public/widgets/underline_tabs.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/phone_formatter.dart';

import '../bloc/bloc.dart';

/// Pushed employees list of the admin: search + role filter, a with-tasks / without-tasks switch and one row per
/// person with the active-task count. Provides [TeamBloc] in staff mode.
class TeamScreen extends StatelessWidget {
  /// Builds the screen.
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => TeamBloc(repository: RepositoryProvider.of<TeamRepository>(ctx))..add(const TeamStarted()),
      child: const _TeamView(),
    );
  }
}

/// Renders the bar, the search row, the switch and the rows.
class _TeamView extends StatefulWidget {
  /// Builds the view.
  const _TeamView();

  @override
  State<_TeamView> createState() => _TeamViewState();
}

/// Owns the search debounce, the switch and the role filter.
class _TeamViewState extends State<_TeamView> {
  /// Delays the search request until typing pauses.
  Timer? _debounce;

  /// Search text controller.
  final _search = TextEditingController();

  /// Selected switch segment: 0 all, 1 with tasks, 2 without tasks.
  /// Selected tab: 0 all, 1 staff, 2 managers.
  int _tab = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// People of the selected tab.
  List<AppUser> _visible(List<AppUser> all) => [
    for (final u in all)
      if (switch (_tab) {
        1 => u.role == UserRole.worker,
        2 => u.role == UserRole.assistant,
        _ => true,
      })
        u,
  ];

  /// Empty state of the selected tab.
  EmptyView _empty() => switch (_tab) {
    1 => EmptyView.tile(icon: AppIcons.user, title: TrWords.tmEStaffT.tr(), message: TrWords.tmEStaffD.tr()),
    2 => EmptyView.tile(icon: AppIcons.shield, title: TrWords.tmEMgrT.tr(), message: TrWords.tmEMgrD.tr()),
    _ => EmptyView.tile(icon: AppIcons.users, title: TrWords.tmEAllT.tr(), message: TrWords.tmEAllD.tr()),
  };

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeamBloc, TeamState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<TeamBloc>();
        final people = _visible(state.items);
        return Scaffold(
          backgroundColor: theme.background,
          body: Column(
            children: [
              InnerBar(
                title: TrWords.tmTitle.tr(),
                actions: [
                  HeaderAction(
                    icon: AppIcons.plus,
                    onTap: () =>
                        context.push('${Routes.memberForm.path}?client=0').then((_) => bloc.add(const TeamRefreshed())),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                child: SearchField(
                  hint: TrWords.tmSearch.tr(),
                  controller: _search,
                  onChanged: (v) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 400), () => bloc.add(TeamSearchChanged(v)));
                  },
                ),
              ),
              UnderlineTabs(
                labels: [TrWords.cAll.tr(), TrWords.tmTabStaff.tr(), TrWords.tmTabMgr.tr()],
                selected: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
              Expanded(
                child: state.items.isEmpty && state.status.isLoading
                    ? const Padding(padding: EdgeInsets.all(16), child: SmartLoading(count: 3))
                    : RefreshList(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h + ScreenSize.bottomInset(context)),
                        gap: 0,
                        onRefresh: () async {
                          bloc.add(const TeamRefreshed());
                          await bloc.stream.firstWhere((s) => !s.refreshing);
                        },
                        onLoadMore: () => bloc.add(const TeamMoreRequested()),
                        isLoadingMore: state.isLoadingMore,
                        placeholder: state.status.isError
                            ? EmptyView(
                                title: TrWords.cLoadFailed.tr(),
                                message: TrWords.cLoadFailedDesc.tr(),
                                icon: AppIcons.alert,
                                onRetry: () => bloc.add(const TeamStarted()),
                              )
                            : _empty(),
                        children: [
                          for (final (i, u) in people.indexed)
                            ListRow(
                              first: i == 0,
                              dividerInset: 52,
                              chevron: false,
                              leading: UserAvatar(u.ref, size: 40.w),
                              title: u.name,
                              titleSize: 15,
                              subtitle: PhoneFormatter.display(u.phone),
                              subtitleColor: theme.textSecondary,
                              trailing: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${u.activeCount}',
                                    style: theme.textStyle.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  Text(TrWords.tmNTasks.tr(), style: theme.cardSubtitle.copyWith(fontSize: 12.sp)),
                                ],
                              ),
                              onTap: () => context.push(Routes.employee.of(u.id)),
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
