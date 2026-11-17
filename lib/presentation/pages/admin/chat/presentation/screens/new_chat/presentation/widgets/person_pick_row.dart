import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/dto/models/user_ref.dart';
import 'package:eco_task/presentation/public/widgets/role_pill.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';

/// One person of the new-chat and new-group lists: avatar, name with the role pill under it and an optional trailing
/// check. Rows of a list are separated by a hairline that starts after the avatar.
class PersonPickRow extends StatelessWidget {
  /// Person drawn by the row.
  final UserRef user;

  /// Widget at the end (the round check of the group picker); omitted when null.
  final Widget? trailing;

  /// Tap handler.
  final VoidCallback onTap;

  /// True for the first row of a list (no top hairline).
  final bool first;

  /// Builds the row.
  const PersonPickRow({super.key, required this.user, required this.onTap, this.trailing, this.first = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 60.h),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w600),
                  ),
                  if (user.role != null) ...[3.h.height, RolePill(user.role!)],
                ],
              ),
            ),
            if (trailing != null) ...[8.w.width, trailing!],
          ],
        ),
      ),
    );
  }
}
