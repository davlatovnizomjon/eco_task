import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/stats_kind.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/floating_tab_bar.dart';
import 'package:eco_task/presentation/public/widgets/large_title_header.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

/// Manager report tab: a large title and four full-width cards (tasks, own, clients, staff), each opening its own
/// statistics screen. Finance and managers are owner-only, so they have no card here.
class ReportsScreen extends StatelessWidget {
  /// Builds the tab.
  const ReportsScreen({super.key});

  /// Statistics a manager may open, in card order.
  static const _kinds = [StatsKind.tasks, StatsKind.mine, StatsKind.clients, StatsKind.staff];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LargeTitleHeader(title: TrWords.sxRoot.tr()),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, FloatingTabBar.inset(context)),
            child: Column(
              children: [
                for (final (i, kind) in _kinds.indexed) ...[
                  if (i > 0) 10.h.height,
                  Expanded(
                    child: CardWidget(
                      onTap: () => context.push(Routes.stats.ofKind(kind.name)),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: theme.panelDecor,
                      child: Row(
                        children: [
                          AppIcon.tile(kind.icon, tone: StatusTone.primary, size: 48),
                          14.w.width,
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kind.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w700),
                                ),
                                3.h.height,
                                Text(
                                  kind.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.cardSubtitle,
                                ),
                              ],
                            ),
                          ),
                          AppIcon(AppIcons.right, size: 18.sp, color: theme.grayText.withValues(alpha: 0.6)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
