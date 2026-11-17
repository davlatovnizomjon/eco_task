import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/dto/models/person_stat.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/ring_chart.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

/// "Most active employee this week": the leader's avatar with a gold star, the done/total sentence and a percent
/// ring, on a green-tinted gradient. Tapping it opens the employee's profile.
class BestEmployeeCard extends StatelessWidget {
  /// Statistics of the leading employee.
  final PersonStat stat;

  /// Builds the card.
  const BestEmployeeCard({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    /// Share of the employee's tasks that are done, 0..1.
    final share = stat.total == 0 ? 0.0 : stat.done / stat.total;
    return GestureDetector(
      onTap: () => context.push(Routes.employee.of(stat.user.id)),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: theme.panelDecor.copyWith(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0, 0.75],
            colors: [theme.primaryTint, theme.cardColor],
          ),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: 3.w.all,
                  decoration: BoxDecoration(color: theme.cardColor, shape: BoxShape.circle),
                  child: UserAvatar(stat.user.ref, size: 52.w),
                ),
                Positioned(
                  right: -2.w,
                  bottom: -2.w,
                  child: Container(
                    width: 26.w,
                    height: 26.w,
                    padding: 2.w.all,
                    decoration: BoxDecoration(color: theme.cardColor, shape: BoxShape.circle),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: theme.gold, shape: BoxShape.circle),
                      child: AppIcon(AppIcons.star, size: 12.w, color: theme.cardColor),
                    ),
                  ),
                ),
              ],
            ),
            12.w.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textStyle.copyWith(fontSize: 17.sp, fontWeight: FontWeight.w700),
                  ),
                  2.h.height,
                  Text(
                    TrWords.dashDoneOf.tr(args: ['${stat.total}', '${stat.done}']),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.cardSubtitle,
                  ),
                ],
              ),
            ),
            12.w.width,
            RingChart(
              size: 48.w,
              thickness: 4.w,
              total: 1,
              track: theme.line,
              segments: [(value: share, color: theme.primary)],
              child: Text(
                '${(share * 100).round()}%',
                style: theme.textStyle.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
