import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/stats_period.dart';
import 'package:eco_task/infrastructure/dto/models/stats_report.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/filter_pill.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import 'stats_head_card.dart';
import 'stats_person_row.dart';

/// Body of the client statistics: the head card (new clients, totals), the "new / all" switch and the matching
/// client list; a period with no new client shows a short note instead of an empty list.
class StatsClients extends StatefulWidget {
  /// Numbers of the selected window.
  final StatsReport report;

  /// Window length, for the "compared with" hint.
  final StatsPeriod period;

  /// Builds the body.
  const StatsClients({super.key, required this.report, required this.period});

  @override
  State<StatsClients> createState() => _StatsClientsState();
}

/// Holds which of the two lists is shown.
class _StatsClientsState extends State<StatsClients> {
  /// True while the "all clients" list is shown.
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    /// Numbers of the window.
    final r = widget.report;

    /// Clients of the selected list.
    final rows = _all ? r.everyone : r.people;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatsHeadCard(
          caption: TrWords.sxNewClients.tr(),
          value: r.total == 0 ? '0' : '+${r.total}',
          delta: r.delta,
          period: widget.period,
          note: r.total == 0 ? TrWords.sxNoNewCaption.tr() : null,
          tiles: [(TrWords.sxAllClients.tr(), '${r.a}'), (TrWords.sxOrgs.tr(), '${r.b}')],
        ),
        14.h.height,
        Row(
          children: [
            FilterPill(
              accent: true,
              label: TrWords.sxTabNew.tr(),
              selected: !_all,
              onTap: () => setState(() => _all = false),
            ),
            8.w.width,
            FilterPill(
              accent: true,
              label: TrWords.cAll.tr(),
              selected: _all,
              onTap: () => setState(() => _all = true),
            ),
          ],
        ),
        14.h.height,
        CardWidget(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: rows.isEmpty ? 22.h : 2.h),
          decoration: theme.panelDecor,
          child: rows.isEmpty
              ? SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Text(
                        TrWords.sxNoNewT.tr(),
                        style: theme.textStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w700),
                      ),
                      4.h.height,
                      Text(
                        TrWords.sxNoNewD.tr(),
                        textAlign: TextAlign.center,
                        style: theme.cardSubtitle.copyWith(fontSize: 14.sp),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (final (i, p) in rows.indexed)
                      StatsPersonRow(
                        first: i == 0,
                        user: p.user,
                        caption: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 7.w),
                            decoration: BoxDecoration(
                              color: theme.info.withValues(alpha: p.isOrg ? 0.12 : 0.0),
                              borderRadius: 9.circular,
                            ),
                            child: Text(
                              (p.isOrg ? TrWords.sxOrg : TrWords.sxPerson).tr(),
                              style: theme.textStyle.copyWith(
                                fontSize: 11.sp,
                                height: 17 / 11,
                                fontWeight: FontWeight.w600,
                                color: p.isOrg ? theme.info : theme.grayText,
                              ),
                            ),
                          ),
                        ),
                        value: _all
                            ? TrWords.sxNTaskShort.tr(args: ['${p.a}'])
                            : (p.date == null ? '' : DateFormatter.dayShort(p.date!)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
