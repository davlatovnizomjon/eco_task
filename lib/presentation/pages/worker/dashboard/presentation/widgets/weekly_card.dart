import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/infrastructure/dto/models/report_summary.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/ring_chart.dart';
import 'package:eco_task/presentation/routes/home_tab.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

/// Weekly progress card: a donut of this week's tasks by outcome with its legend. Tapping it switches to the
/// reports tab; a week without tasks shows a gray ring and a hint instead.
class WeeklyCard extends StatelessWidget {
  /// This week's report.
  final ReportSummary report;

  /// Builds the card.
  const WeeklyCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    /// Tasks of the week; zero switches the card to its empty look.
    final total = report.total;

    /// Legend rows and donut arcs: caption, count and color of every outcome.
    final parts = [
      (label: TrWords.stDone.tr(), value: report.countOf(TaskStatus.done), color: theme.primary),
      (label: TrWords.stProg.tr(), value: report.countOf(TaskStatus.prog), color: theme.info),
      (label: TrWords.stOver.tr(), value: report.overdue, color: theme.warn),
      (label: TrWords.stFail.tr(), value: report.countOf(TaskStatus.fail), color: theme.red),
    ];
    return CardWidget(
      // The reports are the shell's fourth tab.
      onTap: total == 0 ? null : () => homeTab.value = 3,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: theme.panelDecor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(TrWords.wkWeek.tr(), style: theme.textStyle.copyWith(fontWeight: FontWeight.w700)),
              6.w.width,
              Expanded(
                child: Text(
                  '· ${DateFormatter.weekRange(DateTime.now())}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.cardSubtitle,
                ),
              ),
              if (total > 0) AppIcon(AppIcons.right, size: 18.sp, color: theme.grayText),
            ],
          ),
          12.h.height,
          Row(
            children: [
              RingChart(
                size: 96.w,
                thickness: 12.w,
                total: total,
                segments: [for (final p in parts) (value: p.value, color: p.color)],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: theme.textStyle.copyWith(
                        fontSize: 22.sp,
                        height: 26 / 22,
                        fontWeight: FontWeight.w700,
                        color: total == 0 ? theme.grayText : null,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(TrWords.dashTasksWord.tr(), style: theme.cardSubtitle.copyWith(fontSize: 12.sp)),
                  ],
                ),
              ),
              20.w.width,
              Expanded(
                child: total == 0
                    ? Text(
                        TrWords.dashWeekEmpty.tr(),
                        style: theme.cardSubtitle.copyWith(fontSize: 14.sp, height: 20 / 14),
                      )
                    : Column(
                        children: [
                          for (final p in parts)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.5.h),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10.w,
                                    height: 10.w,
                                    decoration: BoxDecoration(color: p.color, borderRadius: 3.circular),
                                  ),
                                  8.w.width,
                                  Expanded(
                                    child: Text(
                                      p.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textStyle.copyWith(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w400,
                                        color: theme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${p.value}',
                                    style: theme.textStyle.copyWith(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
