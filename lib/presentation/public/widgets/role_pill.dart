import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';

/// Small tinted label with a person's role ("Admin", "Menejer", "Xodim", "Mijoz") — shown next to names in
/// assignee lists, group members and pickers.
class RolePill extends StatelessWidget {
  /// Role written on the pill; also picks its color.
  final UserRole role;

  /// Builds the pill.
  const RolePill(this.role, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.h),
      decoration: BoxDecoration(color: role.tone.color.withValues(alpha: 0.12), borderRadius: 10.circular),
      child: Text(
        role.title,
        style: theme.textStyle.copyWith(
          fontSize: 12.sp,
          height: 18 / 12,
          fontWeight: FontWeight.w600,
          color: role.tone.color,
        ),
      ),
    );
  }
}
