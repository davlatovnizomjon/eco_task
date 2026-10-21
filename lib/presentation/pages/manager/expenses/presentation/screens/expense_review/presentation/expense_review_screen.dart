import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/expenses_repository.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/info_row.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/presentation/public/widgets/notice_banner.dart';
import 'package:eco_task/presentation/public/widgets/photo_strip.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/status_chip.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';

import '../bloc/bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';

/// Review of one expense (boss): the entered amount and receipt, an editable
/// approved amount and approve/reject buttons. Provides [ExpenseReviewBloc]
/// over the app-wide expense and task repositories.
class ExpenseReviewScreen extends StatelessWidget {
  /// Id of the task the expense belongs to.
  final String taskId;

  /// Id of the expense to review.
  final String expenseId;

  /// Builds the screen.
  const ExpenseReviewScreen({super.key, required this.taskId, required this.expenseId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ExpenseReviewBloc(
        expenses: RepositoryProvider.of<ExpensesRepository>(ctx),
        tasks: RepositoryProvider.of<TasksRepository>(ctx),
        taskId: taskId,
        expenseId: expenseId,
      )..add(const ExpenseReviewStarted()),
      child: const _ExpenseReviewView(),
    );
  }
}

/// Renders the expense summary, the receipt and the decision controls.
class _ExpenseReviewView extends StatefulWidget {
  /// Builds the screen body.
  const _ExpenseReviewView();

  @override
  State<_ExpenseReviewView> createState() => _ExpenseReviewViewState();
}

/// Owns the approved-amount controller; fills it once the expense arrives.
class _ExpenseReviewViewState extends State<_ExpenseReviewView> {
  /// Controller of the approved-amount field.
  final _amount = TextEditingController();

  /// True after the loaded amount was copied into [_amount].
  bool _filled = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ExpenseReviewBloc>();
    return BlocConsumer<ExpenseReviewBloc, ExpenseReviewState>(
      listenWhen: (prev, cur) => cur.response != null || cur.saved || (!_filled && cur.expense != null),
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        if (state.saved) context.pop();
        if (!_filled && state.expense != null) {
          _filled = true;
          _amount.text = state.amount;
        }
      },
      builder: (context, state) {
        final task = state.task;
        final expense = state.expense;
        return ScreenShell(
          title: TrWords.expReview.tr(),
          padding: EdgeInsets.zero,
          bottomBar: expense == null
              ? null
              : Row(
                  children: [
                    Expanded(
                      child: Btn.danger(
                        text: TrWords.cReject.tr(),
                        icon: AppIcons.x,
                        onPressed: state.busy ? null : () => bloc.add(const ExpenseReviewRejected()),
                      ),
                    ),
                    12.w.width,
                    Expanded(
                      flex: 2,
                      child: Btn(
                        text: TrWords.expApproveBtn.tr(
                          args: [MoneyFormatter.display(MoneyFormatter.parse(state.amount))],
                        ),
                        icon: AppIcons.check,
                        isLoading: state.busy,
                        onPressed: () => bloc.add(const ExpenseReviewApproved()),
                      ),
                    ),
                  ],
                ),
          child: task == null || expense == null
              ? (state.status.isError
                    ? EmptyView(
                        title: TrWords.cLoadFailed.tr(),
                        message: TrWords.cLoadFailedDesc.tr(),
                        icon: AppIcons.alert,
                        onRetry: () => bloc.add(const ExpenseReviewStarted()),
                      )
                    : const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SmartLoading(count: 2)))
              : ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                  children: [
                    Row(
                      children: [
                        UserAvatar(expense.user),
                        10.w.width,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.user.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.cardTitle.copyWith(fontSize: 15.sp),
                              ),
                              Text(DateFormatter.ago(expense.at), style: theme.cardSubtitle),
                            ],
                          ),
                        ),
                        StatusChip.expense(expense.status),
                      ],
                    ),
                    16.h.height,
                    Text(MoneyFormatter.display(expense.amount), style: theme.screenTitle.copyWith(fontSize: 34.sp)),
                    4.h.height,
                    Text(
                      expense.note,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textStyle.copyWith(fontWeight: FontWeight.w400, color: theme.textSecondary),
                    ),
                    16.h.height,
                    if (expense.hasReceipt)
                      PhotoStrip(count: 1, size: 120.w)
                    else
                      NoticeBanner(text: TrWords.expNoReceipt.tr(), icon: AppIcons.alert),
                    16.h.height,
                    CardWidget(
                      child: Column(
                        children: [
                          InfoRow(label: TrWords.expTask.tr(), value: '${task.code} · ${task.title}'),
                          InfoRow(label: TrWords.expReward.tr(), value: MoneyFormatter.display(task.reward)),
                        ],
                      ),
                    ),
                    16.h.height,
                    InputBox(
                      controller: _amount,
                      title: '${TrWords.expApproveAmount.tr()} (\$)',
                      inputType: TextInputType.number,
                      inputFormatters: const [MoneyInputFormatter()],
                      errorText: state.visibleAmountError,
                      onChanged: (v) => bloc.add(ExpenseReviewAmountChanged(v)),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
