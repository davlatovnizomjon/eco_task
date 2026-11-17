import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/dto/models/user_ref.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';

/// One person line of a statistics list: a 40 px avatar, the name, a second line (a pill, a percent) and a right
/// block of one or two stacked texts. Lines sit in a `CardWidget(horizontal 16, vertical 2)`.
class StatsPersonRow extends StatelessWidget {
  /// Person shown.
  final UserRef user;

  /// Widget under the name (a type pill or a gray sentence).
  final Widget caption;

  /// Bold text at the right.
  final String value;

  /// Small gray text under [value]; omitted when null.
  final String? valueNote;

  /// True for the first row of a card — it draws no hairline.
  final bool first;

  /// Builds the row.
  const StatsPersonRow({
    super.key,
    required this.user,
    required this.caption,
    required this.value,
    this.valueNote,
    this.first = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: theme.line, width: 0.5)),
      ),
      child: Row(
        children: [
          UserAvatar(user, size: 40.w),
          12.w.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textStyle),
                2.h.height,
                caption,
              ],
            ),
          ),
          8.w.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textStyle.copyWith(
                  fontSize: valueNote == null ? 13.sp : 15.sp,
                  fontWeight: valueNote == null ? FontWeight.w400 : FontWeight.w700,
                  color: valueNote == null ? theme.grayText : null,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (valueNote != null) Text(valueNote!, style: theme.cardSubtitle.copyWith(fontSize: 11.sp)),
            ],
          ),
        ],
      ),
    );
  }
}
