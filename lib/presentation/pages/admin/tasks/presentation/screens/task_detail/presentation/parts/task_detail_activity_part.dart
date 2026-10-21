import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/comment_list.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/presentation/public/widgets/photo_strip.dart';
import 'package:eco_task/presentation/public/widgets/timeline_view.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import '../../bloc/bloc.dart';

import 'package:eco_task/infrastructure/dto/models/app_user.dart';

/// Bottom of the task details: attached files, the comment thread with its
/// input, and the activity timeline.
class TaskDetailActivityPart extends StatefulWidget {
  /// The task being shown.
  final TaskModel task;

  /// The signed-in account, to label the user's own comments.
  final AppUser me;

  /// Builds the activity section.
  const TaskDetailActivityPart({super.key, required this.task, required this.me});

  @override
  State<TaskDetailActivityPart> createState() => _TaskDetailActivityPartState();
}

/// Owns the inline comment controller.
class _TaskDetailActivityPartState extends State<TaskDetailActivityPart> {
  /// Controller of the inline comment field.
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TaskDetailBloc>();
    final task = widget.task;
    final me = widget.me;
    return Column(
      spacing: 20.h,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (task.files > 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(TrWords.tasksFiles.tr(args: ['${task.files}']), style: theme.sectionLabel),
              8.h.height,
              PhotoStrip(count: task.files, size: 64.w),
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(TrWords.tasksComments.tr(args: ['${task.comments.length}']), style: theme.sectionLabel),
            12.h.height,
            CommentList(comments: task.comments, meId: me.id),
            InputBox(
              controller: _comment,
              hint: TrWords.tasksWriteComment.tr(),
              rightWidget: GestureDetector(
                onTap: () {
                  if (_comment.text.trim().isEmpty) return;
                  bloc.add(TaskDetailCommentSent(_comment.text.trim()));
                  _comment.clear();
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: AppIcon(AppIcons.send, color: theme.primary),
              ),
            ),
          ],
        ),
        if (task.log.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(TrWords.tasksActivity.tr(), style: theme.sectionLabel),
              12.h.height,
              TimelineView(
                steps: [
                  for (final (i, l) in task.log.indexed)
                    TimelineStep(
                      title: l.kind.text(l.args),
                      subtitle: '${l.user.name} · ${DateFormatter.ago(l.at)}',
                      icon: l.kind.icon,
                      done: i == 0,
                    ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}
