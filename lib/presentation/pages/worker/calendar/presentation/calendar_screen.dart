import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/task_priority.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/month_calendar.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import '../bloc/bloc.dart';

/// Calendar tab: a month grid with a dot per deadline and the tasks of the
/// selected day below. Provides [CalendarBloc] over the app-wide
/// [TasksRepository].
class CalendarScreen extends StatelessWidget {
  /// True when the screen was pushed (with a back button) rather than shown as a tab.
  final bool pushed;

  /// Builds the calendar screen.
  const CalendarScreen({super.key, this.pushed = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          CalendarBloc(repository: RepositoryProvider.of<TasksRepository>(ctx))..add(const CalendarStarted()),
      child: _CalendarView(pushed: pushed),
    );
  }
}

/// Renders the grid, the legend and the selected day's list.
class _CalendarView extends StatelessWidget {
  /// True when the screen was pushed rather than shown as a tab.
  final bool pushed;

  /// Builds the calendar body.
  const _CalendarView({required this.pushed});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CalendarBloc, CalendarState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<CalendarBloc>();
        final day = state.tasks.where((t) => DateFormatter.sameDay(t.due, state.selected)).toList()
          ..sort((a, b) => a.due.compareTo(b.due));
        // Legend entries: color and label key.
        final legend = [
          (theme.primary, TrWords.calDue),
          (theme.warn, TrWords.calImportant),
          (theme.red, TrWords.calLate),
        ];
        return ScreenShell(
          title: TrWords.calTitle.tr(),
          big: !pushed,
          showBack: pushed,
          padding: EdgeInsets.zero,
          child: RefreshIndicator(
            color: theme.primary,
            onRefresh: () async {
              bloc.add(const CalendarRefreshed());
              await bloc.stream.firstWhere((s) => !s.refreshing);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h + ScreenSize.bottomInset(context)),
              children: [
                MonthCalendar(
                  selected: state.selected,
                  onSelect: (d) => bloc.add(CalendarDaySelected(d)),
                  onMonthChanged: (m) => bloc.add(CalendarMonthChanged(m)),
                  markers: (d) => [
                    for (final t in state.tasks.where((t) => DateFormatter.sameDay(t.due, d)))
                      if (t.isOverdue)
                        theme.red
                      else if (t.priority == TaskPriority.high && t.status.isOpen)
                        theme.warn
                      else
                        theme.primary,
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final (color, label) in legend) ...[
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      6.w.width,
                      Text(label.tr(), style: theme.cardSubtitle),
                      16.w.width,
                    ],
                  ],
                ),
                16.h.height,
                Text(
                  TrWords.calDayN.tr(args: [DateFormatter.weekdayDay(state.selected), '${day.length}']),
                  style: theme.sectionLabel,
                ),
                8.h.height,
                if (day.isEmpty)
                  CardWidget(child: Text(TrWords.calEmpty.tr(), style: theme.cardSubtitle))
                else
                  CardWidget(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final (i, task) in day.indexed)
                          OptionTile(
                            title: task.title,
                            first: i == 0,
                            subtitle: task.assignees.map((a) => a.user.firstName).join(', '),
                            leading: Text(
                              DateFormatter.time(task.due),
                              style: theme.cardTitle.copyWith(fontSize: 14.sp),
                            ),
                            onTap: () => context.push(Routes.taskDetail.of(task.id)),
                            trailing: AppIcon(
                              task.status == TaskStatus.done
                                  ? AppIcons.checkc
                                  : task.isOverdue
                                  ? AppIcons.alarm
                                  : task.priority.icon,
                              color: task.status == TaskStatus.done
                                  ? theme.primary
                                  : task.isOverdue
                                  ? theme.red
                                  : task.priority.tone.color,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
