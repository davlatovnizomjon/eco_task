import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/presentation/public/widgets/photo_strip.dart';

import '../../bloc/bloc.dart';

/// Worker's "add a comment" sheet: text, up to three photos and a visibility
/// hint. Dispatches to the opener's [TaskDetailBloc].
class TaskCommentDialog extends StatefulWidget {
  /// Builds the sheet body.
  const TaskCommentDialog({super.key});

  @override
  State<TaskCommentDialog> createState() => _TaskCommentDialogState();
}

/// Holds the text controller and the number of attached photo placeholders.
class _TaskCommentDialogState extends State<TaskCommentDialog> {
  /// Controller of the comment text.
  final _text = TextEditingController();

  /// How many placeholder photos are attached.
  int _photos = 0;

  /// Error shown under the field after an empty submit.
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputBox(
          controller: _text,
          lines: 4,
          hint: TrWords.tasksWriteComment.tr(),
          errorText: _error,
          onChanged: (_) => setState(() => _error = null),
        ),
        12.h.height,
        PhotoStrip(count: _photos, onAdd: _photos < 3 ? () => setState(() => _photos++) : null),
        12.h.height,
        Row(
          children: [
            AppIcon(AppIcons.eye, size: 16.sp, color: theme.grayText),
            6.w.width,
            Expanded(
              child: Text(
                TrWords.wVisible.tr(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.cardSubtitle,
              ),
            ),
          ],
        ),
        16.h.height,
        Btn(
          text: TrWords.cSend.tr(),
          icon: AppIcons.send,
          onPressed: () {
            if (_text.text.trim().isEmpty) return setState(() => _error = TrWords.vCommentRequired.tr());
            context.read<TaskDetailBloc>().add(TaskDetailCommentSent(_text.text.trim()));
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
