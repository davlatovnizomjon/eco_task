import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/presentation/public/widgets/accent_task_card.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/section_head.dart';
import 'package:eco_task/presentation/public/widgets/status_chip.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

/// "My tasks": the worker's own open tasks as a stack of cards; a vertical swipe flips to the next card and the
/// dots on the right show the position.
class MyTasksStack extends StatefulWidget {
  /// Open tasks assigned to the worker, nearest deadline first.
  final List<TaskModel> tasks;

  /// Builds the stack.
  const MyTasksStack({super.key, required this.tasks});

  @override
  State<MyTasksStack> createState() => _MyTasksStackState();
}

/// Holds the index of the card on top.
class _MyTasksStackState extends State<MyTasksStack> {
  /// Index of the front card.
  int _index = 0;

  /// Moves the front card by [step], clamped to the list.
  void _flip(int step) => setState(() => _index = (_index + step).clamp(0, widget.tasks.length - 1));

  @override
  Widget build(BuildContext context) {
    final tasks = widget.tasks;
    final task = tasks[_index.clamp(0, tasks.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHead(TrWords.dashMyTasks.tr()),
        11.h.height,
        GestureDetector(
          onVerticalDragEnd: (d) => _flip((d.primaryVelocity ?? 0) < 0 ? 1 : -1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 14.h),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _Layer(offset: 14, scale: 0.9, opacity: 0.5),
                      _Layer(offset: 7, scale: 0.95, opacity: 0.8),
                      _FrontCard(task: task),
                    ],
                  ),
                ),
              ),
              if (tasks.length > 1) ...[
                10.w.width,
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < tasks.length; i++)
                      Container(
                        width: 6.w,
                        height: (i == _index ? 22 : 6).h,
                        margin: EdgeInsets.symmetric(vertical: 2.5.h),
                        decoration: BoxDecoration(
                          color: i == _index ? theme.primary : theme.line,
                          borderRadius: 3.circular,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A faded copy of the card shifted down behind the front one, giving the stacked look.
class _Layer extends StatelessWidget {
  /// Downward shift in logical px.
  final double offset;

  /// Horizontal shrink factor.
  final double scale;

  /// Opacity of the layer.
  final double opacity;

  /// Builds the layer.
  const _Layer({required this.offset, required this.scale, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(0, offset.h),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: Opacity(
            opacity: opacity,
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: 18.circular,
                border: Border.all(color: theme.line),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The front card of the stack: code + status, title, deadline and owner kind.
class _FrontCard extends StatelessWidget {
  /// Task shown on the card.
  final TaskModel task;

  /// Builds the card.
  const _FrontCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return AccentTaskCard(
      accent: task.status.tone.color,
      onTap: () => context.push(Routes.myTask.of(task.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.code,
                  style: theme.textStyle.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.grayText,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              StatusChip.taskCompact(task.status),
            ],
          ),
          8.h.height,
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textStyle.copyWith(fontSize: 17.sp, height: 23 / 17, fontWeight: FontWeight.w700),
          ),
          8.h.height,
          Row(
            children: [
              AppIcon(AppIcons.flag, size: 16.sp, color: theme.textSecondary),
              5.w.width,
              Text(
                DateFormatter.due(task.due),
                style: theme.textStyle.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                  color: theme.textSecondary,
                ),
              ),
              14.w.width,
              AppIcon(AppIcons.user, size: 16.sp, color: theme.textSecondary),
              5.w.width,
              Text(
                TrWords.dashPersonal.tr(),
                style: theme.textStyle.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
