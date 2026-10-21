part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the expense review screen renders itself from.
class ExpenseReviewState extends Equatable {
  /// Id of the expense under review.
  final String expenseId;

  /// Request lifecycle of the load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// The task the expense belongs to; null until the first answer.
  final TaskModel? task;

  /// Raw approved-amount text (thousands-formatted).
  final String amount;

  /// Flipped on the first decision attempt; until then nothing turns red.
  final bool showErrors;

  /// True while the decision is being sent.
  final bool busy;

  /// One-shot: the decision was saved and the screen should close.
  final bool saved;

  /// Builds the initial state.
  const ExpenseReviewState({
    required this.expenseId,
    this.status = ScreenStatus.initial,
    this.response,
    this.task,
    this.amount = '',
    this.showErrors = false,
    this.busy = false,
    this.saved = false,
  });

  /// The expense under review, or null before the task loads.
  ExpenseModel? get expense => task?.expenses.where((e) => e.id == expenseId).firstOrNull;

  /// Validation message for the typed amount against the entered one,
  /// independent of [showErrors]; the entered amount is the upper bound.
  String? get amountError {
    final value = MoneyFormatter.parse(amount);
    return value > 0 && value <= (expense?.amount ?? 0) ? null : TrWords.vAmountRequired.tr();
  }

  /// Amount error the FIELD should display — nothing before the first decision.
  String? get visibleAmountError => showErrors ? amountError : null;

  /// Copies the state; [response] and [saved] reset unless passed, so each
  /// fires once per emit.
  ExpenseReviewState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    TaskModel? task,
    String? amount,
    bool? showErrors,
    bool? busy,
    bool saved = false,
  }) => ExpenseReviewState(
    expenseId: expenseId,
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    task: task ?? this.task,
    amount: amount ?? this.amount,
    showErrors: showErrors ?? this.showErrors,
    busy: busy ?? this.busy,
    saved: saved,
  );

  @override
  List<Object?> get props => [status, response, task, amount, showErrors, busy, saved];
}
