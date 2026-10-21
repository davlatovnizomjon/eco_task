import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';
import 'package:eco_task/domain/common/enums/expense_kind.dart';

part 'event.dart';
part 'state.dart';

/// Drives the "add expense" form of one task: keeps the typed values,
/// validates the amount on submit and sends the expense for review.
class ExpenseFormBloc extends Bloc<ExpenseFormEvent, ExpenseFormState> {
  /// Data source of task writes; owned by the app root.
  final TasksRepository repository;

  /// Id of the task the expense is entered against.
  final String taskId;

  /// Wires the handlers of the form.
  ExpenseFormBloc({required this.repository, required this.taskId}) : super(const ExpenseFormState()) {
    on<ExpenseFormAmountChanged>((event, emit) => emit(state.copyWith(amount: event.value)));
    on<ExpenseFormKindChanged>((event, emit) => emit(state.copyWith(kind: event.value)));
    on<ExpenseFormNoteChanged>((event, emit) => emit(state.copyWith(note: event.value)));
    on<ExpenseFormReceiptToggled>((event, emit) => emit(state.copyWith(hasReceipt: !state.hasReceipt)));
    on<ExpenseFormSubmitted>(_onSubmitted);
  }

  /// Validates the amount, then sends the expense. A failed validation emits
  /// the message and flips `showErrors` (the field turns red).
  Future<void> _onSubmitted(ExpenseFormSubmitted event, Emitter<ExpenseFormState> emit) async {
    final invalid = state.amountError;
    if (invalid != null) {
      emit(state.copyWith(showErrors: true, response: MessageErrorResponse(invalid)));
      return;
    }
    emit(state.copyWith(status: ScreenStatus.loading, showErrors: true));
    try {
      await repository.addExpense(
        taskId,
        amount: MoneyFormatter.parse(state.amount),
        kind: state.kind.name,
        note: state.note.trim(),
        hasReceipt: state.hasReceipt,
      );
      emit(state.copyWith(status: ScreenStatus.success, saved: true));
    } catch (e) {
      emit(
        state.copyWith(
          status: ScreenStatus.initial,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
        ),
      );
    }
  }
}
