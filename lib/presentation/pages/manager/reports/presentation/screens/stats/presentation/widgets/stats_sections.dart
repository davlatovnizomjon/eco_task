import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/stats_kind.dart';
import 'package:eco_task/domain/common/enums/stats_period.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/infrastructure/dto/models/stats_report.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/section_head.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';

import 'stats_bar_chart.dart';
import 'stats_clients.dart';
import 'stats_fact_row.dart';
import 'stats_head_card.dart';
import 'stats_person_row.dart';

/// Builds the cards of a statistics screen from its [StatsReport]: which cards, in which order, depends on the
/// [StatsKind].
class StatsSections {
  /// Private constructor — the class is a namespace.
  const StatsSections._();

  /// Cards of [kind] for the window of [period] starting [offset] periods back.
  static List<Widget> build(StatsKind kind, StatsReport r, StatsPeriod period, int offset) {
    /// Captions under the bars of this window.
    final labels = barLabels(period, offset, r.bars.length);
    return switch (kind) {
      StatsKind.finance => [
        StatsHeadCard(
          caption: kind.headline,
          value: MoneyFormatter.display(r.total),
          delta: r.delta,
          period: period,
          tiles: [
            (TrWords.sxDoneTasks.tr(), TrWords.sxNPcs.tr(args: ['${r.a}'])),
            (TrWords.sxAvgPrice.tr(), MoneyFormatter.display(r.b)),
          ],
          child: StatsBarChart(values: r.bars, labels: labels),
        ),
        _planCard(r),
        _factsCard([
          _fact(
            AppIcons.checkc,
            StatusTone.primary,
            TrWords.sxPaid,
            '${r.facts[0]}',
            MoneyFormatter.display(r.facts[1]),
          ),
          if (r.facts[2] > 0)
            _fact(
              AppIcons.clock,
              StatusTone.warn,
              TrWords.sxPending,
              '${r.facts[2]}',
              MoneyFormatter.display(r.facts[3]),
            ),
          _fact(AppIcons.xc, StatusTone.error, TrWords.sxCanceled, '${r.facts[4]}', MoneyFormatter.display(r.facts[5])),
        ]),
      ],
      StatsKind.tasks => [
        StatsHeadCard(
          caption: kind.headline,
          value: TrWords.sxNPcs.tr(args: ['${r.total}']),
          delta: r.delta,
          period: period,
          child: _splitBar(r.split),
        ),
        _chartCard(TrWords.sxDoneTasks.tr(), r, labels),
        _factsCard([
          _timely(r.facts[0]),
          _overdue(r.facts[1].toInt(), TrWords.sxOverdueD.tr()),
          StatsFactRow(
            icon: AppIcons.history,
            tone: StatusTone.info,
            title: TrWords.sxAvgTime.tr(),
            subtitle: TrWords.sxAvgTimeD.tr(),
            value: TrWords.sxNDays.tr(args: [r.facts[2].toString().replaceAll('.', ',')]),
          ),
        ]),
      ],
      StatsKind.mine => [
        StatsHeadCard(
          caption: kind.headline,
          value: TrWords.sxNPcs.tr(args: ['${r.total}']),
          delta: r.delta,
          period: period,
          tiles: [
            (TrWords.sxDoneShort.tr(), TrWords.sxNPcs.tr(args: ['${r.a}'])),
            (TrWords.sxIncome.tr(), MoneyFormatter.display(r.b)),
          ],
        ),
        _chartCard(TrWords.sxCreatedTasks.tr(), r, labels),
        _factsCard([
          _timely(r.facts[0]),
          _overdue(r.facts[1].toInt(), TrWords.sxOverdueD.tr()),
          StatsFactRow(
            icon: AppIcons.users,
            tone: StatusTone.info,
            title: TrWords.sxMyClients.tr(),
            subtitle: TrWords.sxMyClientsD.tr(),
            value: TrWords.sxNPcs.tr(args: ['${r.facts[2]}']),
          ),
        ]),
      ],
      StatsKind.clients => [StatsClients(report: r, period: period)],
      StatsKind.staff => [
        StatsHeadCard(
          caption: kind.headline,
          value: TrWords.sxNPeople.tr(args: ['${r.total}']),
          delta: r.delta,
          deltaIsCount: true,
          period: period,
          tiles: [
            (TrWords.sxDoneTasks.tr(), TrWords.sxNPcs.tr(args: ['${r.a}'])),
            (TrWords.sxOnTimeShort.tr(), '${r.b}%'),
          ],
        ),
        SectionHead(TrWords.sxTopStaff.tr()),
        CardWidget(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
          decoration: theme.panelDecor,
          child: Column(
            children: [
              for (final (i, p) in r.people.indexed)
                StatsPersonRow(
                  first: i == 0,
                  user: p.user,
                  caption: Text(
                    TrWords.sxPctOnTime.tr(args: ['${p.a}']),
                    style: theme.cardSubtitle.copyWith(fontSize: 12.sp),
                  ),
                  value: TrWords.sxNPcs.tr(args: ['${p.b}']),
                  valueNote: TrWords.sxDid.tr(),
                ),
            ],
          ),
        ),
      ],
      StatsKind.managers => [
        StatsHeadCard(
          caption: kind.headline,
          value: TrWords.sxNPeople.tr(args: ['${r.total}']),
          period: period,
          note: TrWords.sxPrevSame.tr(args: ['${r.previous}']),
          tiles: [
            (TrWords.sxCreatedTasks.tr(), TrWords.sxNPcs.tr(args: ['${r.a}'])),
            (TrWords.sxIncome.tr(), MoneyFormatter.display(r.b)),
          ],
        ),
        SectionHead(TrWords.sxMgrResult.tr()),
        CardWidget(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
          decoration: theme.panelDecor,
          child: Column(
            children: [
              for (final (i, p) in r.people.indexed)
                StatsPersonRow(
                  first: i == 0,
                  user: p.user,
                  caption: Text(
                    TrWords.sxNCreated.tr(args: ['${p.a}']),
                    style: theme.cardSubtitle.copyWith(fontSize: 12.sp),
                  ),
                  value: MoneyFormatter.display(p.b),
                  valueNote: TrWords.sxIncomeLow.tr(),
                ),
            ],
          ),
        ),
      ],
    };
  }

  /// Captions of the [count] bars of a window: weekday names, "N-week" or month initials.
  static List<String> barLabels(StatsPeriod period, int offset, int count) {
    /// First day of the window.
    final start = period.start(offset);
    return [
      for (var i = 0; i < count; i++)
        switch (period) {
          StatsPeriod.week => DateFormatter.weekdayShort(start.add(Duration(days: i))),
          StatsPeriod.month => TrWords.sxWeekN.tr(args: ['${i + 1}']),
          StatsPeriod.year => DateFormatter.monthName(DateTime(start.year, i + 1))[0],
        },
    ];
  }

  /// Title of the window written between the arrows: a day range, "Oktabr, 2026" or the year.
  static String periodTitle(StatsPeriod period, int offset) {
    /// First day of the window.
    final start = period.start(offset);
    return switch (period) {
      StatsPeriod.week => () {
        /// Last day (Sunday) of the week.
        final end = start.add(const Duration(days: 6));
        return '${start.day} – ${DateFormatter.dayShort(end)}, ${end.year}';
      }(),
      StatsPeriod.month => '${DateFormatter.monthName(start)}, ${start.year}',
      StatsPeriod.year => '${start.year}',
    };
  }

  /// Card with a [title] and the bar chart of [r].
  static Widget _chartCard(String title, StatsReport r, List<String> labels) => CardWidget(
    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
    decoration: theme.panelDecor,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textStyle.copyWith(fontWeight: FontWeight.w700)),
        10.h.height,
        StatsBarChart(values: r.bars, labels: labels),
      ],
    ),
  );

  /// Plan against result: a percent chip, a progress bar and both sums.
  static Widget _planCard(StatsReport r) {
    /// Share of the plan reached, clamped to 100.
    final pct = r.plan == 0 ? 0 : (r.total * 100 / r.plan).round().clamp(0, 100);
    return CardWidget(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: theme.panelDecor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(TrWords.sxPlan.tr(), style: theme.textStyle.copyWith(fontWeight: FontWeight.w700)),
              ),
              Container(
                height: 26.h,
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.14), borderRadius: 13.circular),
                child: Text('$pct%', style: theme.badgeText.copyWith(color: theme.primary)),
              ),
            ],
          ),
          10.h.height,
          ClipRRect(
            borderRadius: 4.circular,
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8.h,
              color: theme.primary,
              backgroundColor: theme.cardColorLight,
            ),
          ),
          10.h.height,
          Row(
            children: [
              Expanded(child: _pair(TrWords.sxResult.tr(), MoneyFormatter.display(r.total))),
              _pair(TrWords.sxPlanWord.tr(), MoneyFormatter.display(r.plan)),
            ],
          ),
        ],
      ),
    );
  }

  /// "Caption **value**" pair under the plan bar.
  static Widget _pair(String caption, String value) => Text.rich(
    TextSpan(
      text: '$caption ',
      children: [
        TextSpan(
          text: value,
          style: TextStyle(fontWeight: FontWeight.w700, color: theme.text),
        ),
      ],
    ),
    style: theme.cardSubtitle,
  );

  /// Card that holds a list of [StatsFactRow]s; the first row loses its hairline.
  static Widget _factsCard(List<StatsFactRow> rows) => CardWidget(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
    decoration: theme.panelDecor,
    child: Column(
      children: [
        for (final (i, row) in rows.indexed)
          StatsFactRow(
            first: i == 0,
            icon: row.icon,
            tone: row.tone,
            title: row.title,
            subtitle: row.subtitle,
            value: row.value,
            tinted: row.tinted,
          ),
      ],
    ),
  );

  /// Finance fact row: tile, [title] key, "N ta vazifa" count and the sum.
  static StatsFactRow _fact(String icon, StatusTone tone, String title, String count, String sum) => StatsFactRow(
    icon: icon,
    tone: tone,
    title: title.tr(),
    subtitle: TrWords.sxNTasks.tr(args: [count]),
    value: sum,
  );

  /// "On time" row with its percent.
  static StatsFactRow _timely(num pct) => StatsFactRow(
    icon: AppIcons.clock,
    title: TrWords.sxOnTime.tr(),
    subtitle: TrWords.sxOnTimeD.tr(),
    value: '$pct%',
  );

  /// "Overdue" row: red count, or a calm note when there is none.
  static StatsFactRow _overdue(int count, String hint) => StatsFactRow(
    icon: AppIcons.alert,
    tone: StatusTone.error,
    title: TrWords.sxOverdue.tr(),
    subtitle: count == 0 ? TrWords.sxOverdueNone.tr() : hint,
    value: TrWords.sxNPcs.tr(args: ['$count']),
    tinted: count > 0,
  );

  /// Thin stacked bar of the four task outcomes with a two-column legend.
  static Widget _splitBar(List<int> split) {
    /// Outcome captions and colors in the order of [split]: done, in progress, new, canceled.
    final parts = [
      (TrWords.stDone.tr(), theme.primary),
      (TrWords.stProg.tr(), theme.info),
      (TrWords.stNew.tr(), theme.warn),
      (TrWords.sxCancShort.tr(), theme.red),
    ];
    return Column(
      children: [
        ClipRRect(
          borderRadius: 5.circular,
          child: Row(
            children: [
              for (final (i, n) in split.indexed)
                if (n > 0) ...[
                  if (i > 0) 3.w.width,
                  Expanded(
                    flex: n,
                    child: Container(height: 10.h, color: parts[i].$2),
                  ),
                ],
            ],
          ),
        ),
        12.h.height,
        Wrap(
          runSpacing: 10.h,
          children: [
            for (final (i, n) in split.indexed)
              FractionallySizedBox(
                widthFactor: 0.5,
                child: Padding(
                  padding: EdgeInsets.only(right: i.isEven ? 20.w : 0),
                  child: Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(color: parts[i].$2, borderRadius: 4.circular),
                      ),
                      8.w.width,
                      Expanded(
                        child: Text(
                          parts[i].$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.cardSubtitle,
                        ),
                      ),
                      Text('$n', style: theme.textStyle.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
