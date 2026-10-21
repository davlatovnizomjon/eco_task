import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/expenses_repository.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/presentation/public/dialogs/reject_dialog.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/expense_row.dart';
import 'package:eco_task/presentation/public/widgets/photo_strip.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/segmented_tabs.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/status_chip.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';

import '../bloc/bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';

/// Approval queue (boss): submitted results with approve/return buttons and the
/// pending expenses. Provides [ReviewBloc] over the app-wide task and expense
/// repositories.
class ReviewScreen extends StatelessWidget {
  /// Builds the queue screen.
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ReviewBloc(
        tasks: RepositoryProvider.of<TasksRepository>(ctx),
        expenses: RepositoryProvider.of<ExpensesRepository>(ctx),
      )..add(const ReviewStarted()),
      child: const _ReviewView(),
    );
  }
}

/// Renders the tab switch and the selected list.
class _ReviewView extends StatelessWidget {
  /// Builds the queue body.
  const _ReviewView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReviewBloc, ReviewState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<ReviewBloc>();
        final empty = state.tab == 0 ? state.results.isEmpty : state.pending.isEmpty;
        return ScreenShell(
          title: TrWords.revTitle.tr(),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 6.h),
                child: SegmentedTabs(
                  labels: [
                    TrWords.revResults.tr(args: ['${state.results.length}']),
                    TrWords.revExpenses.tr(args: ['${state.pending.length}']),
                  ],
                  selected: state.tab,
                  onChanged: (i) => bloc.add(ReviewTabChanged(i)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: state.status.isLoading && empty
                      ? const SmartLoading(count: 3)
                      : RefreshList(
                          onRefresh: () async {
                            bloc.add(const ReviewRefreshed());
                            await bloc.stream.firstWhere((s) => !s.refreshing);
                          },
                          placeholder: state.status.isError
                              ? EmptyView(
                                  title: TrWords.cLoadFailed.tr(),
                                  message: TrWords.cLoadFailedDesc.tr(),
                                  icon: AppIcons.alert,
                                  onRetry: () => bloc.add(const ReviewStarted()),
                                )
                              : EmptyView(
                                  title: TrWords.revEmpty.tr(),
                                  message: TrWords.revEmptyDesc.tr(),
                                  icon: AppIcons.checkc,
                                ),
                          children: [
                            if (state.tab == 0)
                              for (final task in state.results)
                                CardWidget(
                                  onTap: () => context.push(Routes.taskDetail.of(task.id)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          UserAvatar(task.assignees.first.user),
                                          10.w.width,
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  task.assignees.first.user.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.cardTitle.copyWith(fontSize: 15.sp),
                                                ),
                                                Text(
                                                  TrWords.revSubmitted.tr(
                                                    args: [DateFormatter.ago(task.submittedAt ?? task.due)],
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.cardSubtitle,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(task.code, style: theme.fieldLabel.copyWith(color: theme.grayText)),
                                        ],
                                      ),
                                      10.h.height,
                                      Text(
                                        task.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.cardTitle,
                                      ),
                                      if (task.result.isNotEmpty) ...[
                                        6.h.height,
                                        Text(
                                          '«${task.result}»',
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.cardSubtitle.copyWith(color: theme.textSecondary),
                                        ),
                                      ],
                                      if (task.files > 0) ...[
                                        10.h.height,
                                        Row(
                                          children: [
                                            PhotoStrip(count: task.files.clamp(0, 3), size: 40.w),
                                            10.w.width,
                                            Expanded(
                                              child: Text(
                                                TrWords.revPhotosExp.tr(
                                                  args: ['${task.files}', MoneyFormatter.display(task.enteredSum)],
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.cardSubtitle,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (task.submittedAt != null && task.submittedAt!.isAfter(task.due)) ...[
                                        10.h.height,
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: StatusChip.overdue(
                                            task.submittedAt!.difference(task.due).inDays.clamp(1, 99),
                                          ),
                                        ),
                                      ],
                                      14.h.height,
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Btn.danger(
                                              text: TrWords.cReject.tr(),
                                              icon: AppIcons.x,
                                              height: 40.h,
                                              onPressed: () => showBottomDialog(
                                                RejectDialog(
                                                  assigneeName: task.assignees.first.user.firstName,
                                                  onSubmit: (reason, extend) => bloc.add(
                                                    ReviewReturned(taskId: task.id, reason: reason, extend: extend),
                                                  ),
                                                ),
                                                context,
                                                title: TrWords.revRejectTitle.tr(),
                                              ),
                                            ),
                                          ),
                                          8.w.width,
                                          Expanded(
                                            child: Btn(
                                              text: TrWords.cApprove.tr(),
                                              icon: AppIcons.check,
                                              height: 40.h,
                                              isLoading: state.busy,
                                              onPressed: () => bloc.add(ReviewApproved(task.id)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                            else
                              CardWidget(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  children: [
                                    for (final (i, entry) in state.pending.indexed)
                                      ExpenseRow(
                                        entry: entry,
                                        first: i == 0,
                                        onTap: () => context.push(
                                          Routes.expenseReview.ofExpense(entry.taskId, entry.expense.id),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
