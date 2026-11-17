import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/filter_pill.dart';
import 'package:eco_task/presentation/public/widgets/month_grid.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

/// Deadline picker sheet: quick day chips, a month calendar and time chips.
/// Pops with the chosen moment, or null when dismissed.
class DueDateDialog extends StatefulWidget {
  /// Deadline currently set on the form.
  final DateTime initial;

  /// Builds the sheet body.
  const DueDateDialog({super.key, required this.initial});

  @override
  State<DueDateDialog> createState() => _DueDateDialogState();
}

/// Holds the draft day and hour before the user confirms.
class _DueDateDialogState extends State<DueDateDialog> {
  /// Chosen day, time stripped.
  late DateTime _day = DateTime(widget.initial.year, widget.initial.month, widget.initial.day);

  /// Chosen hour of the day.
  late int _hour = widget.initial.hour;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    // Quick choices: label and the day each one stands for.
    final quick = [
      (TrWords.cToday.tr(), base),
      (TrWords.cTomorrow.tr(), base.add(const Duration(days: 1))),
      (TrWords.formWeekLater.tr(), base.add(const Duration(days: 7))),
    ];
    final picked = DateTime(_day.year, _day.month, _day.day, _hour);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final (label, day) in quick)
              FilterPill(
                label: label,
                selected: DateFormatter.sameDay(_day, day),
                onTap: () => setState(() => _day = day),
              ),
          ],
        ),
        8.h.height,
        MonthGrid(compact: true, selected: _day, firstDay: base, onSelect: (day) => setState(() => _day = day)),
        8.h.height,
        Text(TrWords.formTime.tr(), style: theme.sectionLabel),
        8.h.height,
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final h in const [9, 12, 15, 18])
              FilterPill(
                label: '${h.toString().padLeft(2, '0')}:00',
                selected: _hour == h,
                onTap: () => setState(() => _hour = h),
              ),
          ],
        ),
        16.h.height,
        Btn(
          text: TrWords.formReady.tr(args: [DateFormatter.dayTime(picked)]),
          onPressed: () => Navigator.pop(context, picked),
        ),
      ],
    );
  }
}
