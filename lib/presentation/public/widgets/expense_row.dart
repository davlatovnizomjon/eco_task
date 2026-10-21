import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/dto/models/expense_entry.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';

import 'app_icon.dart';
import 'option_tile.dart';
import 'user_avatar.dart';

/// One expense line of the review queue and the expenses list: who entered it,
/// for which task, the amount and whether a receipt is attached.
class ExpenseRow extends StatelessWidget {
  /// The expense with its task.
  final ExpenseEntry entry;

  /// Opens the expense (review or pay).
  final VoidCallback onTap;

  /// True for the first row of a card — it draws no hairline.
  final bool first;

  /// Builds the row.
  const ExpenseRow({super.key, required this.entry, required this.onTap, this.first = false});

  @override
  Widget build(BuildContext context) {
    final e = entry.expense;
    return OptionTile(
      title: e.note,
      first: first,
      subtitle: '${entry.taskId} · ${e.user.firstName} · ${DateFormatter.due(e.at, withTime: false)}',
      leading: UserAvatar(e.user, size: 36.w),
      onTap: onTap,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(MoneyFormatter.display(e.amount), style: theme.cardTitle),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                e.hasReceipt ? AppIcons.receipt : AppIcons.alert,
                size: 14.sp,
                color: e.hasReceipt ? theme.primary : theme.warn,
              ),
              3.w.width,
              Text(
                (e.hasReceipt ? TrWords.expHasReceipt : TrWords.expNoReceipt).tr(),
                style: theme.cardSubtitle.copyWith(
                  fontSize: 12.sp,
                  color: e.hasReceipt ? theme.textSecondary : theme.warn,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
