import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/app_user.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/segmented_tabs.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/status_chip.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

import '../bloc/bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';

/// Staff and client directory (boss) with search, grouping by team and a
/// button that opens the account form. Provides [TeamBloc] over the app-wide
/// [TeamRepository].
class TeamScreen extends StatelessWidget {
  /// Builds the directory screen.
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => TeamBloc(repository: RepositoryProvider.of<TeamRepository>(ctx))..add(const TeamStarted()),
      child: const _TeamView(),
    );
  }
}

/// Renders the tab switch, the search field and the grouped list.
class _TeamView extends StatefulWidget {
  /// Builds the directory body.
  const _TeamView();

  @override
  State<_TeamView> createState() => _TeamViewState();
}

/// Owns the search debounce timer.
class _TeamViewState extends State<_TeamView> {
  /// Delays the search request until the user stops typing.
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeamBloc, TeamState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<TeamBloc>();
        // Staff grouped by team, keeping the server order within each group.
        final teams = <String, List<AppUser>>{};
        for (final u in state.items) {
          (teams[u.team] ??= []).add(u);
        }
        return ScreenShell(
          title: TrWords.teamTitle.tr(),
          padding: EdgeInsets.zero,
          actions: [
            Btn.compact(
              text: state.clients ? TrWords.teamClientBtn.tr() : TrWords.teamInvite.tr(),
              icon: AppIcons.plus,
              onPressed: () => context.push('${Routes.memberForm.path}?client=${state.clients ? 1 : 0}'),
            ),
          ],
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                child: Column(
                  children: [
                    SegmentedTabs(
                      labels: [TrWords.teamTabStaff.tr(), TrWords.teamTabClients.tr()],
                      selected: state.clients ? 1 : 0,
                      onChanged: (i) => bloc.add(TeamTabChanged(clients: i == 1)),
                    ),
                    10.h.height,
                    InputBox(
                      key: ValueKey(state.clients),
                      hint: (state.clients ? TrWords.teamSearchC : TrWords.teamSearch).tr(),
                      leftIcon: AppIcons.search,
                      onChanged: (v) {
                        _debounce?.cancel();
                        _debounce = Timer(const Duration(milliseconds: 400), () => bloc.add(TeamSearchChanged(v)));
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: state.items.isEmpty && state.status.isLoading
                      ? const SmartLoading(count: 3)
                      : RefreshList(
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
                              : EmptyView(title: TrWords.cEmptyTitle.tr(), icon: AppIcons.users),
                          children: [
                            if (state.clients) ...[
                              CardWidget(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  children: [
                                    for (final (i, u) in state.items.indexed)
                                      OptionTile(
                                        title: u.name,
                                        first: i == 0,
                                        subtitle:
                                            '${u.team} · ${u.activeCount == 0 ? TrWords.teamNoRequests.tr() : TrWords.teamRequestsN.tr(args: ['${u.activeCount}'])}',
                                        leading: UserAvatar(u.ref, size: 40.w),
                                      ),
                                  ],
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppIcon(AppIcons.shield, size: 18.sp, color: theme.primary),
                                  8.w.width,
                                  Expanded(
                                    child: Text(
                                      TrWords.teamClientsHelp.tr(),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.cardSubtitle,
                                    ),
                                  ),
                                ],
                              ),
                            ] else
                              for (final entry in teams.entries)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(entry.key, style: theme.sectionLabel)),
                                        Text(
                                          TrWords.teamLead.tr(
                                            args: [
                                              entry.value
                                                  .firstWhere(
                                                    (u) => u.role == UserRole.assistant,
                                                    orElse: () => entry.value.first,
                                                  )
                                                  .firstName,
                                            ],
                                          ),
                                          style: theme.cardSubtitle,
                                        ),
                                      ],
                                    ),
                                    8.h.height,
                                    CardWidget(
                                      padding: EdgeInsets.zero,
                                      child: Column(
                                        children: [
                                          for (final (i, u) in entry.value.indexed)
                                            OptionTile(
                                              title: u.name,
                                              first: i == 0,
                                              subtitle: u.role == UserRole.assistant
                                                  ? TrWords.teamSenior.tr()
                                                  : TrWords.teamTasksN.tr(args: ['${u.activeCount}']),
                                              leading: UserAvatar(u.ref, size: 40.w),
                                              onTap: () => context.push(Routes.employee.of(u.id)),
                                              trailing: u.role == UserRole.assistant
                                                  ? StatusChip(
                                                      label: TrWords.roleManager.tr(),
                                                      tone: StatusTone.review,
                                                      icon: AppIcons.shield,
                                                    )
                                                  : null,
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
