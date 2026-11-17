import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

/// Header of a tab root screen: a large 32 px title with primary-colored action buttons and an optional
/// block (segmented control, search row) under it, closed by a hairline.
class LargeTitleHeader extends StatelessWidget {
  /// Screen title.
  final String title;

  /// Trailing action buttons (usually [HeaderAction]s).
  final List<Widget> actions;

  /// Extra content under the title row; omitted when null.
  final Widget? bottom;

  /// Replaces the title text (home greeting row); the title is then only used for semantics.
  final Widget? custom;

  /// Builds the header.
  const LargeTitleHeader({super.key, required this.title, this.actions = const [], this.bottom, this.custom});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, MediaQuery.of(context).padding.top + 8.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.92),
        border: Border(bottom: BorderSide(color: theme.line, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44.h,
            child:
                custom ??
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textStyle.copyWith(
                          fontSize: 32.sp,
                          height: 38 / 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    ...actions,
                  ],
                ),
          ),
          if (bottom != null) ...[10.h.height, bottom!],
        ],
      ),
    );
  }
}
