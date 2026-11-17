import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';

/// Bottom sheet asking why the task was not done: a title, a multi-line reason with a 500-character counter and the
/// red "send" button. Resolves to the trimmed reason; an empty reason marks the field red instead of closing.
class TaskFailSheet extends StatefulWidget {
  /// Builds the sheet.
  const TaskFailSheet({super.key});

  /// Longest reason the field accepts.
  static const maxLength = 500;

  /// Opens the sheet; resolves to the reason, or null when it was dismissed.
  static Future<String?> show(BuildContext context) => showBottomDialog<String>(const TaskFailSheet(), context);

  @override
  State<TaskFailSheet> createState() => _TaskFailSheetState();
}

/// Holds the reason text and whether a submit was already attempted.
class _TaskFailSheetState extends State<TaskFailSheet> {
  /// Controller of the reason field.
  final _reason = TextEditingController();

  /// True once "send" was tapped with an empty reason — turns the field red.
  bool _missing = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  /// Closes the sheet with the reason, or flags the empty field.
  void _submit() {
    /// Reason without surrounding spaces.
    final text = _reason.text.trim();
    if (text.isEmpty) return setState(() => _missing = true);
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TrWords.mtFailT.tr(),
          style: theme.textStyle.copyWith(fontSize: 20.sp, height: 26 / 20, fontWeight: FontWeight.w700),
        ),
        2.h.height,
        Text(TrWords.mtFailD.tr(), style: theme.cardSubtitle.copyWith(fontSize: 14.sp)),
        14.h.height,
        InputBox(
          controller: _reason,
          hint: TrWords.mtFailHint.tr(),
          lines: 4,
          errorText: _missing ? TrWords.mtFailRequired.tr() : null,
          inputFormatters: [LengthLimitingTextInputFormatter(TaskFailSheet.maxLength)],
          onChanged: (_) => setState(() => _missing = false),
        ),
        6.h.height,
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            TrWords.mtPages.tr(args: ['${_reason.text.length}', '${TaskFailSheet.maxLength}']),
            style: theme.cardSubtitle.copyWith(fontSize: 12.sp),
          ),
        ),
        14.h.height,
        Btn(
          text: TrWords.cSend.tr(),
          height: 52.h,
          onPressed: _submit,
          decoration: BoxDecoration(color: theme.red, borderRadius: 16.circular),
          textStyle: theme.textStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w700, color: theme.cardColor),
        ),
      ],
    );
  }
}
