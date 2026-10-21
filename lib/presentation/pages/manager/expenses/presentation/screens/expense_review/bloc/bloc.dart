import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/expenses_repository.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';
import 'package:eco_task/infrastructure/dto/models/expense_model.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';

part 'event.dart';
part 'state.dart';

/// Drives the review of one expense: loads its task, keeps the amount the boss
/// types, validates it against the entered amount and sends the decision.
class ExpenseReviewBloc extends Bloc<ExpenseReviewEvent, ExpenseReviewState> {
  /// Data source of the review action; owned by the app root.
  final ExpensesRepository expenses;

  /// Data source of the task and its expenses; owned by the app root.
  final TasksRepository tasks;

  /// Id of the task the expense belongs to.
  final String taskId;

  /// Id of the expense under review.
  final String expenseId;

  /// Wires the handlers of the screen.
  ExpenseReviewBloc({required this.expenses, required this.tasks, required this.taskId, required this.expenseId})
    : super(ExpenseReviewState(expenseId: expenseId)) {
    on<ExpenseReviewStarted>(_onStarted);
    on<ExpenseReviewAmountChanged>((event, emit) => emit(state.copyWith(amount: event.value)));
    on<ExpenseReviewApproved>(_onApproved);
    on<ExpenseReviewRejected>((event, emit) => _send(emit, null));
  }

  /// Loads the task (cache first) and prefills the approved amount with the
  /// entered one.
  Future<void> _onStarted(ExpenseReviewStarted event, Emitter<ExpenseReviewState> emit) async {
    emit(state.copyWith(task: tasks.cachedTask(taskId), status: ScreenStatus.loading));
    try {
      final task = await tasks.getTask(taskId);
      final expense = task.expenses.firstWhere((e) => e.id == expenseId);
      emit(state.copyWith(task: task, amount: MoneyFormatter.number(expense.amount), status: ScreenStatus.success));
    } catch (e) {
      emit(
        state.copyWith(status: ScreenStatus.error, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()),
      );
    }
  }

  /// Validates the typed amount (1..entered), then approves for it.
  Future<void> _onApproved(ExpenseReviewApproved event, Emitter<ExpenseReviewState> emit) async {
    final invalid = state.amountError;
    if (invalid != null) {
      emit(state.copyWith(showErrors: true, response: MessageErrorResponse(invalid)));
      return;
    }
    await _send(emit, MoneyFormatter.parse(state.amount));
  }

  /// Sends the decision: approve for [amount], or reject when it is null.
  Future<void> _send(Emitter<ExpenseReviewState> emit, int? amount) async {
    emit(state.copyWith(busy: true, showErrors: true));
    try {
      await expenses.review(taskId, expenseId, amount: amount);
      emit(state.copyWith(busy: false, saved: true));
    } catch (e) {
      emit(state.copyWith(busy: false, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }
}
