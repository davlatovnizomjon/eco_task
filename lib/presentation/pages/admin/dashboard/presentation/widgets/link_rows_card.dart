import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/header_action.dart';

/// One row of a [LinkRowsCard]: tile glyph, texts, an optional red counter and the tap target.
typedef LinkRow = ({String icon, StatusTone tone, String title, String subtitle, int badge, VoidCallback onTap});

/// Panel of tappable rows separated by hairlines — "waiting for approval" and the first-steps list of an empty
/// dashboard. Every row has a tinted tile, a title with a hint, an optional counter and a chevron.
class LinkRowsCard extends StatelessWidget {
  /// Rows from top to bottom.
  final List<LinkRow> rows;

  /// Horizontal padding of a row (14 on the dashboard, 16 on the first-steps list).
  final double inset;

  /// Builds the panel.
  const LinkRowsCard({super.key, required this.rows, this.inset = 14});

  @override
  Widget build(BuildContext context) {
    return CardWidget(
      padding: EdgeInsets.zero,
      decoration: theme.panelDecor,
      child: Column(
        children: [
          for (final (i, row) in rows.indexed)
            InkWell(
              onTap: row.onTap,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: inset.w, vertical: 12.h),
                decoration: BoxDecoration(
                  border: i == 0 ? null : Border(top: BorderSide(color: theme.line)),
                ),
                child: Row(
                  children: [
                    AppIcon.tile(row.icon, tone: row.tone, size: 40),
                    12.w.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textStyle.copyWith(fontWeight: FontWeight.w600),
                          ),
                          2.h.height,
                          Text(row.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.cardSubtitle),
                        ],
                      ),
                    ),
                    if (row.badge > 0) ...[12.w.width, CountBadge(row.badge, ring: theme.cardColor)],
                    12.w.width,
                    AppIcon(AppIcons.right, color: theme.grayText),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
