import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/infrastructure/dto/models/task_assignee.dart';
import 'package:eco_task/presentation/public/widgets/role_pill.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';

/// One assignee: avatar, name and the role pill. Shared by the screen's card and the full-list sheet.
class AssigneeLine extends StatelessWidget {
  /// Assignee drawn by the line.
  final TaskAssignee assignee;

  /// True for the first line of a list (no top hairline).
  final bool first;

  /// Height of the line (56 on the card, 60 in the sheet).
  final double height;

  /// Builds the line.
  const AssigneeLine({super.key, required this.assignee, this.first = false, this.height = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: height.h),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: theme.line)),
      ),
      child: Row(
        children: [
          UserAvatar(assignee.user, size: 32.w),
          8.w.width,
          Expanded(
            child: Text(assignee.user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textStyle),
          ),
          8.w.width,
          RolePill(assignee.user.role ?? UserRole.worker),
        ],
      ),
    );
  }
}
