import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import '../widgets/app_icon.dart';
import '../widgets/btn.dart';
import '../widgets/card_widget.dart';
import '../widgets/filter_pill.dart';
import '../widgets/input_box.dart';
import '../widgets/option_tile.dart';

/// Bottom-sheet body that sends a submitted task back for rework: a reason
/// chip, a note to the assignee and an "extend the deadline" switch. Shared by
/// the review queue and the task details screen; the caller performs the action.
class RejectDialog extends StatefulWidget {
  /// Name of the assignee who gets the notification (shown in the hint).
  final String assigneeName;

  /// Called with the final reason text and the extend flag when the boss confirms.
  final void Function(String reason, bool extend) onSubmit;

  /// Builds the sheet body.
  const RejectDialog({super.key, required this.assigneeName, required this.onSubmit});

  @override
  State<RejectDialog> createState() => _RejectDialogState();
}

/// Holds the chosen reason chip, the note controller and the extend switch.
class _RejectDialogState extends State<RejectDialog> {
  /// Predefined reasons, in display order.
  static final _reasons = [TrWords.revR1, TrWords.revR2, TrWords.revR3];

  /// Index of the selected reason chip.
  int _reason = 0;

  /// True when the deadline should be pushed back.
  bool _extend = false;

  /// Controller of the free-text note.
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(TrWords.revReason.tr(), style: theme.sectionLabel),
        8.h.height,
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (var i = 0; i < _reasons.length; i++)
              FilterPill(label: _reasons[i].tr(), selected: _reason == i, onTap: () => setState(() => _reason = i)),
          ],
        ),
        16.h.height,
        InputBox(controller: _note, title: TrWords.revNote.tr(), lines: 3),
        6.h.height,
        Text(
          TrWords.revReturnHelp.tr(args: [widget.assigneeName]),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.cardSubtitle,
        ),
        12.h.height,
        CardWidget(
          padding: EdgeInsets.zero,
          child: OptionTile(
            title: TrWords.revExtend.tr(),
            first: true,
            leading: AppIcon(AppIcons.cal, color: theme.textSecondary),
            trailing: Switch(value: _extend, onChanged: (v) => setState(() => _extend = v)),
          ),
        ),
        20.h.height,
        Row(
          children: [
            Expanded(
              child: Btn.unActive(text: TrWords.cCancel.tr(), onPressed: () => Navigator.pop(context)),
            ),
            10.w.width,
            Expanded(
              child: Btn.danger(
                text: TrWords.revReturn.tr(),
                icon: AppIcons.x,
                onPressed: () {
                  widget.onSubmit(_note.text.trim().isEmpty ? _reasons[_reason].tr() : _note.text.trim(), _extend);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
