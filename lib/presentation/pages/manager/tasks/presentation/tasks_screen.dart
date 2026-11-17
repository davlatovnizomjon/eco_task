import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/domain/common/enums/task_due_filter.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/task_query.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/floating_tab_bar.dart';
import 'package:eco_task/presentation/public/widgets/header_action.dart';
import 'package:eco_task/presentation/public/widgets/large_title_header.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/search_field.dart';
import 'package:eco_task/presentation/public/widgets/underline_tabs.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

import '../bloc/bloc.dart';
import 'dialogs/tasks_filter_dialog.dart';
import 'widgets/task_list_row.dart';

/// Manager tasks tab: large title with the "new" action, search + filter, six status tabs and the flat task list. Provides [TasksBloc] over the app-wide [TasksRepository].
class TasksScreen extends StatelessWidget {
  /// Builds the tab.
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => TasksBloc(
        repository: RepositoryProvider.of<TasksRepository>(ctx),
        team: RepositoryProvider.of<TeamRepository>(ctx),
      )..add(const TasksStarted()),
      child: const _TasksView(),
    );
  }
}

/// Renders the header, the quick switch and the grouped list.
class _TasksView extends StatefulWidget {
  /// Builds the view.
  const _TasksView();

  @override
  State<_TasksView> createState() => _TasksViewState();
}

/// Owns the search debounce.
class _TasksViewState extends State<_TasksView> {
  /// Delays the search request until typing pauses.
  Timer? _debounce;

  /// Search text controller.
  final _search = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Index of the status tab that matches [query]: all, new, in progress, overdue, done, failed.
  static int _tabOf(TaskQuery query) {
    if (query.overdueOnly) return 3;
    if (query.statuses.length != 1) return 0;
    return switch (query.statuses.first) {
      TaskStatus.fresh => 1,
      TaskStatus.prog => 2,
      TaskStatus.done => 4,
      TaskStatus.fail => 5,
      _ => 0,
    };
  }

  /// Empty state of status tab [tab]: its glyph, tone, title and hint.
  static EmptyView _empty(int tab) => switch (tab) {
    1 => EmptyView.tile(
      icon: AppIcons.newIcon,
      tone: StatusTone.neutral,
      title: TrWords.tlENewT.tr(),
      message: TrWords.tlENewD.tr(),
    ),
    2 => EmptyView.tile(
      icon: AppIcons.prog,
      tone: StatusTone.info,
      title: TrWords.tlEProgT.tr(),
      message: TrWords.tlEProgD.tr(),
    ),
    3 => EmptyView.tile(
      icon: AppIcons.alarm,
      tone: StatusTone.warn,
      title: TrWords.tlEOverT.tr(),
      message: TrWords.tlEOverD.tr(),
    ),
    4 => EmptyView.tile(icon: AppIcons.checkc, title: TrWords.tlEDoneT.tr(), message: TrWords.tlEDoneD.tr()),
    5 => EmptyView.tile(
      icon: AppIcons.xc,
      tone: StatusTone.error,
      title: TrWords.tlEFailT.tr(),
      message: TrWords.tlEFailD.tr(),
    ),
    _ => EmptyView.tile(icon: AppIcons.tasks, title: TrWords.tlEAllT.tr(), message: TrWords.tlEAllD.tr()),
  };

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TasksBloc, TasksState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<TasksBloc>();
        final query = state.query;
        return Column(
          children: [
            LargeTitleHeader(
              title: TrWords.tasksTitle.tr(),
              actions: [HeaderAction(icon: AppIcons.plus, onTap: () => context.push(Routes.taskNew.path))],
              bottom: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SearchField(
                          hint: TrWords.tlSearch.tr(),
                          controller: _search,
                          onChanged: (v) {
                            _debounce?.cancel();
                            _debounce = Timer(
                              const Duration(milliseconds: 400),
                              () => bloc.add(TasksQueryChanged(query.copyWith(search: v))),
                            );
                          },
                        ),
                      ),
                      8.w.width,
                      SquareIconButton(
                        icon: AppIcons.filter,
                        active: query.people.isNotEmpty || query.due != TaskDueFilter.any,
                        onTap: () => TasksFilterDialog.show(context, bloc),
                      ),
                    ],
                  ),
                  4.h.height,
                  UnderlineTabs(
                    scrollable: true,
                    divider: false,
                    labels: [
                      TrWords.cAll.tr(),
                      TrWords.stNew.tr(),
                      TrWords.stProg.tr(),
                      TrWords.dashOverdue.tr(),
                      TrWords.tlDoneTab.tr(),
                      TrWords.tlFailTab.tr(),
                    ],
                    selected: _tabOf(query),
                    onChanged: (i) => bloc.add(
                      TasksQueryChanged(
                        query.copyWith(
                          statuses: switch (i) {
                            1 => {TaskStatus.fresh},
                            2 => {TaskStatus.prog},
                            4 => {TaskStatus.done},
                            5 => {TaskStatus.fail},
                            _ => <TaskStatus>{},
                          },
                          overdueOnly: i == 3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.status.isLoading
                  ? const Padding(padding: EdgeInsets.all(16), child: SmartLoading())
                  : RefreshList(
                      padding: EdgeInsets.fromLTRB(16.w, 2.h, 16.w, FloatingTabBar.inset(context)),
                      gap: 0,
                      onRefresh: () async {
                        bloc.add(const TasksRefreshed());
                        await bloc.stream.firstWhere((s) => !s.refreshing);
                      },
                      onLoadMore: () => bloc.add(const TasksMoreRequested()),
                      isLoadingMore: state.isLoadingMore,
                      placeholder: state.status.isError
                          ? EmptyView(
                              title: TrWords.cLoadFailed.tr(),
                              message: TrWords.cLoadFailedDesc.tr(),
                              icon: AppIcons.alert,
                              onRetry: () => bloc.add(const TasksStarted()),
                            )
                          : _empty(_tabOf(query)),
                      children: [
                        for (final (i, task) in state.items.indexed)
                          TaskListRow(
                            task: task,
                            first: i == 0,
                            onTap: () => context.push(Routes.taskDetail.of(task.id)),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
