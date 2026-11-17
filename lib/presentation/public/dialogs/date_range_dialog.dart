import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import '../widgets/app_icon.dart';
import '../widgets/btn.dart';
import '../widgets/card_widget.dart';

/// Bottom sheet that picks a date range on a month grid: the first tap sets the start, the second the end (taps
/// are reordered when the second is earlier). "Select" resolves to the range.
class DateRangeDialog extends StatefulWidget {
  /// Range shown as selected when the sheet opens.
  final DateTimeRange? initial;

  /// Builds the sheet.
  const DateRangeDialog({super.key, this.initial});

  /// Opens the sheet; resolves to the picked range, or null when it was dismissed.
  static Future<DateTimeRange?> show(BuildContext context, {DateTimeRange? initial}) =>
      showBottomDialog<DateTimeRange>(DateRangeDialog(initial: initial), context);

  @override
  State<DateRangeDialog> createState() => _DateRangeDialogState();
}

/// Holds the visible month and the two ends of the range.
class _DateRangeDialogState extends State<DateRangeDialog> {
  /// First day of the month on screen.
  late DateTime _month = DateTime(
    (widget.initial?.start ?? DateTime.now()).year,
    (widget.initial?.start ?? DateTime.now()).month,
  );

  /// Start of the range; null until the first tap.
  late DateTime? _from = widget.initial?.start;

  /// End of the range; null until the second tap.
  late DateTime? _to = widget.initial?.end;

  /// Short weekday captions, Monday first.
  static const _weekdays = [TrWords.wd1, TrWords.wd2, TrWords.wd3, TrWords.wd4, TrWords.wd5, TrWords.wd6, TrWords.wd7];

  /// Applies a tap on [day]: starts a new range, or closes the open one.
  void _tap(DateTime day) => setState(() {
    if (_from == null || _to != null) {
      _from = day;
      _to = null;
    } else if (day.isBefore(_from!)) {
      _to = _from;
      _from = day;
    } else {
      _to = day;
    }
  });

  @override
  Widget build(BuildContext context) {
    /// Empty cells before the 1st so it lands under its weekday.
    final lead = _month.weekday - 1;

    /// Number of days in the visible month.
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TrWords.fltRange.tr(),
          style: theme.textStyle.copyWith(fontSize: 20.sp, height: 26 / 20, fontWeight: FontWeight.w700),
        ),
        14.h.height,
        CardWidget(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: theme.panelDecor,
          child: Row(
            children: [
              AppIcon(AppIcons.cal, size: 22.sp, color: theme.primary),
              12.w.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(TrWords.fltRangeSel.tr(), style: theme.cardSubtitle.copyWith(fontSize: 12.sp)),
                    2.h.height,
                    Text(
                      _from == null
                          ? TrWords.fltRangeNone.tr()
                          : '${DateFormatter.dayShort(_from!)} — ${DateFormatter.dayShort(_to ?? _from!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textStyle.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        14.h.height,
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormatter.monthYear(_month),
                style: theme.textStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
            ),
            for (final (step, icon) in [(-1, AppIcons.left), (1, AppIcons.right)])
              IconButton(
                onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + step)),
                icon: AppIcon(icon, color: theme.text),
              ),
          ],
        ),
        8.h.height,
        Row(
          children: [
            for (final key in _weekdays)
              Expanded(
                child: Text(
                  key.tr(),
                  textAlign: TextAlign.center,
                  style: theme.cardSubtitle.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        8.h.height,
        for (var row = 0; row < ((lead + days) / 7).ceil(); row++)
          Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: Row(
              children: [for (var col = 0; col < 7; col++) Expanded(child: _cell(row * 7 + col - lead + 1, days))],
            ),
          ),
        10.h.height,
        Row(
          children: [
            Expanded(
              flex: 10,
              child: Btn.unActive(text: TrWords.cCancel.tr(), height: 52.h, onPressed: () => Navigator.pop(context)),
            ),
            10.w.width,
            Expanded(
              flex: 16,
              child: Btn(
                text: TrWords.fltSelect.tr(),
                height: 52.h,
                onPressed: _from == null
                    ? null
                    : () => Navigator.pop(context, DateTimeRange(start: _from!, end: _to ?? _from!)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// One day cell: empty outside the month, a filled circle on a range end, a tinted band between the ends.
  Widget _cell(int n, int days) {
    if (n < 1 || n > days) return SizedBox(height: 42.h);

    /// The date of this cell.
    final day = DateTime(_month.year, _month.month, n);

    /// True on the start or the end of the range.
    final isEnd =
        (_from != null && DateFormatter.sameDay(day, _from!)) || (_to != null && DateFormatter.sameDay(day, _to!));

    /// True strictly inside, or on an end of, a closed range — draws the tinted band.
    final inRange = _from != null && _to != null && !day.isBefore(_from!) && !day.isAfter(_to!);
    return GestureDetector(
      onTap: () => _tap(day),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 42.h,
        alignment: Alignment.center,
        color: inRange ? theme.primary.withValues(alpha: 0.14) : null,
        child: Container(
          width: 38.w,
          height: 38.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: isEnd ? theme.primary : null, shape: BoxShape.circle),
          child: Text(
            '$n',
            style: theme.textStyle.copyWith(
              fontWeight: isEnd ? FontWeight.w700 : (inRange ? FontWeight.w500 : FontWeight.w400),
              color: isEnd ? theme.onPrimary : theme.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
