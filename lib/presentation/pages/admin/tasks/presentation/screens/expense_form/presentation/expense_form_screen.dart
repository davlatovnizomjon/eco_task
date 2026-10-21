import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/expense_kind.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/filter_pill.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/presentation/public/widgets/photo_strip.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';

import '../bloc/bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';

/// "Add expense" form of a task (worker). Provides [ExpenseFormBloc] over the
/// app-wide [TasksRepository].
class ExpenseFormScreen extends StatelessWidget {
  /// Id of the task the expense belongs to.
  final String taskId;

  /// Builds the form screen.
  const ExpenseFormScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ExpenseFormBloc(repository: RepositoryProvider.of<TasksRepository>(ctx), taskId: taskId),
      child: const _ExpenseFormView(),
    );
  }
}

/// Renders the amount, type, note and receipt fields.
class _ExpenseFormView extends StatelessWidget {
  /// Builds the form body.
  const _ExpenseFormView();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ExpenseFormBloc>();
    final task = RepositoryProvider.of<TasksRepository>(context).cachedTask(bloc.taskId);
    return BlocConsumer<ExpenseFormBloc, ExpenseFormState>(
      listenWhen: (prev, cur) => cur.response != null || cur.saved,
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        if (state.saved) context.pop();
      },
      builder: (context, state) => ScreenShell(
        title: TrWords.expAdd.tr(),
        backIcon: AppIcons.x,
        padding: EdgeInsets.zero,
        bottomBar: Btn(
          text: TrWords.expToReview.tr(),
          icon: AppIcons.send,
          isLoading: state.status.isLoading,
          onPressed: () => bloc.add(const ExpenseFormSubmitted()),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
          children: [
            Row(
              children: [
                AppIcon(AppIcons.tasks, size: 18.sp, color: theme.grayText),
                8.w.width,
                Expanded(
                  child: Text(
                    '${bloc.taskId}${task == null ? '' : ' · ${task.title}'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.cardSubtitle.copyWith(color: theme.textSecondary),
                  ),
                ),
              ],
            ),
            18.h.height,
            InputBox(
              title: '${TrWords.expAmount.tr()} (\$)',
              hint: '0',
              inputType: TextInputType.number,
              inputFormatters: const [MoneyInputFormatter()],
              errorText: state.visibleAmountError,
              onChanged: (v) => bloc.add(ExpenseFormAmountChanged(v)),
            ),
            18.h.height,
            Text(TrWords.expType.tr(), style: theme.fieldLabel),
            6.h.height,
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final kind in ExpenseKind.values)
                  FilterPill(
                    label: kind.title,
                    icon: kind.icon,
                    selected: state.kind == kind,
                    onTap: () => bloc.add(ExpenseFormKindChanged(kind)),
                  ),
              ],
            ),
            18.h.height,
            InputBox(title: TrWords.expNote.tr(), onChanged: (v) => bloc.add(ExpenseFormNoteChanged(v))),
            18.h.height,
            Text(TrWords.expReceipt.tr(), style: theme.fieldLabel),
            6.h.height,
            PhotoStrip(
              count: state.hasReceipt ? 1 : 0,
              onAdd: state.hasReceipt ? null : () => bloc.add(const ExpenseFormReceiptToggled()),
            ),
            if (state.hasReceipt)
              Btn.ghost(
                text: TrWords.cClear.tr(),
                icon: AppIcons.x,
                onPressed: () => bloc.add(const ExpenseFormReceiptToggled()),
              ),
            6.h.height,
            Text(TrWords.expReceiptHelp.tr(), style: theme.cardSubtitle),
          ],
        ),
      ),
    );
  }
}
