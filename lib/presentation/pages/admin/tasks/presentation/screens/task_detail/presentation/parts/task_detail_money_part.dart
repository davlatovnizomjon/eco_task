import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/expense_status.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/info_row.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/status_chip.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';

import 'package:eco_task/infrastructure/dto/models/app_user.dart';

/// Reward and expenses of the task: the facts card and the expense rows with a
/// review shortcut for the boss. A worker sees only their own expenses.
class TaskDetailMoneyPart extends StatelessWidget {
  /// The task being shown.
  final TaskModel task;

  /// The signed-in account; decides which expenses are visible.
  final AppUser me;

  /// Builds the money section.
  const TaskDetailMoneyPart({super.key, required this.task, required this.me});

  @override
  Widget build(BuildContext context) {
    final boss = me.role.isBoss;
    final expenses = boss ? task.expenses : task.expenses.where((e) => e.user.id == me.id).toList();
    return Column(
      spacing: 20.h,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (task.reward > 0 || expenses.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(TrWords.tasksRewardExp.tr(), style: theme.sectionLabel),
              8.h.height,
              CardWidget(
                child: Column(
                  children: [
                    InfoRow(label: TrWords.tasksRewardTotal.tr(), value: MoneyFormatter.display(task.reward)),
                    InfoRow(
                      label: boss ? TrWords.tasksEntered.tr() : TrWords.tasksMyExpense.tr(),
                      value: MoneyFormatter.display(expenses.fold(0, (s, e) => s + e.amount)),
                    ),
                    InfoRow(
                      label: TrWords.tasksApproved.tr(),
                      value: MoneyFormatter.display(
                        expenses.fold(0, (s, e) => s + (e.status == ExpenseStatus.approved ? e.approvedAmount : 0)),
                      ),
                      valueColor: theme.primary,
                    ),
                    InfoRow(
                      label: TrWords.tasksPayment.tr(),
                      value: (task.status == TaskStatus.done && task.isPaid ? TrWords.esPaid : TrWords.esPend).tr(),
                      valueColor: task.isPaid ? theme.info : theme.warn,
                    ),
                  ],
                ),
              ),
              if (expenses.isNotEmpty) ...[
                8.h.height,
                CardWidget(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (i, e) in expenses.indexed)
                        OptionTile(
                          first: i == 0,
                          title: e.status == ExpenseStatus.approved && e.approvedAmount != e.amount
                              ? '${MoneyFormatter.display(e.amount)} → ${MoneyFormatter.display(e.approvedAmount)}'
                              : MoneyFormatter.display(e.amount),
                          subtitle: '${e.note} · ${e.user.firstName} · ${DateFormatter.day(e.at)}',
                          leading: AppIcon.tile(AppIcons.receipt, tone: e.status.tone, size: 36),
                          trailing: boss && e.status == ExpenseStatus.pending
                              ? Btn.compact(
                                  text: TrWords.cView.tr(),
                                  onPressed: () => context.push(Routes.expenseReview.ofExpense(task.id, e.id)),
                                )
                              : StatusChip.expense(e.status),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}
