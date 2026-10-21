import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/expense_status.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/expenses_repository.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/presentation/public/dialogs/public_dialog.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/expense_row.dart';
import 'package:eco_task/presentation/public/widgets/filter_pill.dart';
import 'package:eco_task/presentation/public/widgets/info_row.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/status_chip.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';

import '../bloc/bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';

/// Expenses and payouts (boss): money totals, a filtered expense list, and the
/// rewards of completed tasks. Provides [ExpensesBloc] over the app-wide
/// expense and task repositories.
class ExpensesScreen extends StatelessWidget {
  /// Builds the screen.
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ExpensesBloc(
        expenses: RepositoryProvider.of<ExpensesRepository>(ctx),
        tasks: RepositoryProvider.of<TasksRepository>(ctx),
      )..add(const ExpensesStarted()),
      child: const _ExpensesView(),
    );
  }
}

/// Renders totals, filter tabs, the expense list and the reward payouts.
class _ExpensesView extends StatelessWidget {
  /// Builds the screen body.
  const _ExpensesView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExpensesBloc, ExpensesState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<ExpensesBloc>();
        final totals = state.totals;
        final tabs = [TrWords.esPend, TrWords.esOk, TrWords.esRej, TrWords.esPaid];
        return ScreenShell(
          title: TrWords.expTitle.tr(),
          padding: EdgeInsets.zero,
          child: totals == null
              ? (state.status.isError
                    ? EmptyView(
                        title: TrWords.cLoadFailed.tr(),
                        message: TrWords.cLoadFailedDesc.tr(),
                        icon: AppIcons.alert,
                        onRetry: () => bloc.add(const ExpensesStarted()),
                      )
                    : const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SmartLoading(count: 3)))
              : RefreshList(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  gap: 16,
                  onRefresh: () async {
                    bloc.add(const ExpensesRefreshed());
                    await bloc.stream.firstWhere((s) => !s.refreshing);
                  },
                  onLoadMore: () => bloc.add(const ExpensesMoreRequested()),
                  isLoadingMore: state.isLoadingMore,
                  children: [
                    CardWidget(
                      child: Column(
                        children: [
                          InfoRow(label: TrWords.expEntered.tr(), value: MoneyFormatter.display(totals.entered)),
                          InfoRow(
                            label: TrWords.expApproved.tr(),
                            value: MoneyFormatter.display(totals.approved),
                            valueColor: theme.primary,
                          ),
                          InfoRow(
                            label: TrWords.expRejected.tr(),
                            value: MoneyFormatter.display(totals.rejected),
                            valueColor: theme.red,
                          ),
                          InfoRow(label: TrWords.expPaidStaff.tr(), value: MoneyFormatter.display(totals.paidOut)),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 36.h,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final (i, label) in tabs.indexed)
                            Padding(
                              padding: 8.w.right,
                              child: FilterPill(
                                label: '${label.tr()} · ${totals.counts[ExpensesBloc.filters[i]] ?? 0}',
                                selected: state.filter == i,
                                onTap: () => bloc.add(ExpensesFilterChanged(i)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (state.items.isEmpty)
                      SizedBox(
                        height: 180.h,
                        child: EmptyView(title: TrWords.expEmpty.tr(), icon: AppIcons.receipt),
                      )
                    else
                      CardWidget(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (final (i, entry) in state.items.indexed)
                              ExpenseRow(
                                entry: entry,
                                first: i == 0,
                                onTap: () {
                                  final expense = entry.expense;
                                  if (expense.status == ExpenseStatus.pending) {
                                    context.push(Routes.expenseReview.ofExpense(entry.taskId, expense.id));
                                    return;
                                  }
                                  if (expense.status != ExpenseStatus.approved || expense.isPaid) return;
                                  showCenterDialog(
                                    PublicDialog.confirm(
                                      title: TrWords.expPay.tr(),
                                      subTitle:
                                          '${entry.expense.note} · ${MoneyFormatter.display(entry.expense.approvedAmount)}',
                                      activeBtnText: TrWords.cOk.tr(),
                                      unActiveBtnText: TrWords.cCancel.tr(),
                                      onActiveBtnPressed: () => bloc.add(ExpensePaid(entry.taskId, entry.expense.id)),
                                    ),
                                    context,
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    Text(TrWords.expRewards.tr(), style: theme.sectionLabel),
                    CardWidget(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final (i, task) in state.rewards.indexed)
                            OptionTile(
                              title: '${task.code} · ${task.assignees.map((a) => a.user.firstName).join(', ')}',
                              first: i == 0,
                              subtitle: '${task.title} · ${MoneyFormatter.display(task.reward)}',
                              leading: UserAvatar(task.assignees.first.user, size: 28.w),
                              trailing: task.isPaid
                                  ? StatusChip(label: TrWords.esPaid.tr(), tone: StatusTone.info, icon: AppIcons.wallet)
                                  : StatusChip(
                                      label: TrWords.esPend.tr(),
                                      tone: StatusTone.neutral,
                                      icon: AppIcons.clock,
                                    ),
                              onTap: task.isPaid
                                  ? null
                                  : () => showCenterDialog(
                                      PublicDialog.confirm(
                                        title: TrWords.expPay.tr(),
                                        subTitle: '${task.title} · ${MoneyFormatter.display(task.reward)}',
                                        activeBtnText: TrWords.cOk.tr(),
                                        unActiveBtnText: TrWords.cCancel.tr(),
                                        onActiveBtnPressed: () => bloc.add(ExpenseRewardPaid(task.id)),
                                      ),
                                      context,
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
