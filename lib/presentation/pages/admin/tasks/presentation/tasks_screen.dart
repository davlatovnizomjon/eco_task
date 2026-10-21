import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/user_ref.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/filter_pill.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/task_card.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

import '../bloc/bloc.dart';
import 'dialogs/tasks_filter_dialog.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';

/// All tasks of the boss's scope with search, quick filters, a filter sheet and
/// a "create task" button. A tab root screen. Provides [TasksBloc] over the
/// app-wide [TasksRepository].
class TasksScreen extends StatelessWidget {
  /// Builds the task list screen.
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => TasksBloc(repository: RepositoryProvider.of<TasksRepository>(ctx))..add(const TasksStarted()),
      child: const _TasksView(),
    );
  }
}

/// Renders the search row, filter chips and the paged list.
class _TasksView extends StatefulWidget {
  /// Builds the list body.
  const _TasksView();

  @override
  State<_TasksView> createState() => _TasksViewState();
}

/// Owns the search debounce timer.
class _TasksViewState extends State<_TasksView> {
  /// Delays the search request until the user stops typing.
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final team = RepositoryProvider.of<SessionRepository>(context).user.value?.user;
    return BlocConsumer<TasksBloc, TasksState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<TasksBloc>();
        final query = state.query;
        // People who appear on the loaded tasks, offered as assignee filters.
        final people = <String, UserRef>{
          for (final t in state.items)
            for (final a in t.assignees) a.userId: a.user,
        }.values.toList();
        // Quick chips: label, statuses to keep, overdue flag.
        final chips = [
          (TrWords.cAll.tr(), <TaskStatus>{}, false, null),
          (TrWords.stProg.tr(), {TaskStatus.prog}, false, null),
          (TrWords.stRev.tr(), {TaskStatus.rev}, false, null),
          (TrWords.stOver.tr(), <TaskStatus>{}, true, AppIcons.alarm),
          (TrWords.stNew.tr(), {TaskStatus.fresh}, false, null),
        ];
        return ScreenShell(
          title: TrWords.tasksTitle.tr(),
          subtitle: team?.role == UserRole.assistant ? team?.team : null,
          big: true,
          showBack: false,
          padding: EdgeInsets.zero,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push(Routes.taskNew.path),
            backgroundColor: theme.primary,
            foregroundColor: theme.onPrimary,
            icon: AppIcon(AppIcons.plus, color: theme.onPrimary),
            label: Text(
              TrWords.tasksNewBtn.tr(),
              style: theme.textStyle.copyWith(fontWeight: FontWeight.w700, color: theme.onPrimary),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                child: Row(
                  children: [
                    Expanded(
                      child: InputBox(
                        hint: TrWords.cSearchName.tr(),
                        leftIcon: AppIcons.search,
                        onChanged: (v) {
                          _debounce?.cancel();
                          _debounce = Timer(
                            const Duration(milliseconds: 400),
                            () => bloc.add(TasksQueryChanged(query.copyWith(search: v))),
                          );
                        },
                      ),
                    ),
                    10.w.width,
                    GestureDetector(
                      onTap: () => showBottomDialog(
                        BlocProvider.value(
                          value: bloc,
                          child: TasksFilterDialog(people: people),
                        ),
                        context,
                        title: TrWords.tasksFilter.tr(),
                      ),
                      child: Badge(
                        isLabelVisible: query.activeCount > 0,
                        label: Text('${query.activeCount}'),
                        child: Container(
                          width: 48.w,
                          height: 48.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: 12.circular,
                            border: Border.all(color: theme.line),
                          ),
                          child: AppIcon(AppIcons.filter, color: theme.text),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 36.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  children: [
                    for (final (label, statuses, overdue, icon) in chips)
                      Padding(
                        padding: 8.w.right,
                        child: FilterPill(
                          label: label,
                          icon: icon,
                          selected:
                              query.overdueOnly == overdue &&
                              query.statuses.length == statuses.length &&
                              query.statuses.containsAll(statuses),
                          onTap: () =>
                              bloc.add(TasksQueryChanged(query.copyWith(statuses: statuses, overdueOnly: overdue))),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 6.h, 8.w, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        query.who == null
                            ? TrWords.tasksAssigneeAll.tr()
                            : '${TrWords.tasksAssignee.tr()}: ${people.where((p) => p.id == query.who).firstOrNull?.firstName ?? ''}',
                        style: theme.cardSubtitle,
                      ),
                    ),
                    Btn.ghost(
                      text: query.sort.shortTitle,
                      icon: AppIcons.sort,
                      onPressed: () => bloc.add(TasksQueryChanged(query.copyWith(sort: query.sort.next))),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: state.status.isLoading
                      ? const SmartLoading()
                      : RefreshList(
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
                              : EmptyView(
                                  title: TrWords.tasksEmpty.tr(),
                                  message: TrWords.tasksEmptyDesc.tr(),
                                  icon: AppIcons.search,
                                ),
                          children: [
                            for (final task in state.items)
                              TaskCard(task: task, onTap: () => context.push(Routes.taskDetail.of(task.id))),
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
