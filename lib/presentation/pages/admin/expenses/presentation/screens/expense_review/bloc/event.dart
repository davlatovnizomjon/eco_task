part of 'bloc.dart';

/// Base of every action the expense review screen can dispatch.
sealed class ExpenseReviewEvent {
  /// Allows the events to have const constructors.
  const ExpenseReviewEvent();
}

/// The screen opened — load the task and its expense.
final class ExpenseReviewStarted extends ExpenseReviewEvent {
  /// Fires the load.
  const ExpenseReviewStarted();
}

/// The boss typed in the approved-amount field.
final class ExpenseReviewAmountChanged extends ExpenseReviewEvent {
  /// Raw (thousands-formatted) field text.
  final String value;

  /// Carries the new amount text.
  const ExpenseReviewAmountChanged(this.value);
}

/// The boss pressed "approve".
final class ExpenseReviewApproved extends ExpenseReviewEvent {
  /// Validates the amount and approves.
  const ExpenseReviewApproved();
}

/// The boss pressed "reject".
final class ExpenseReviewRejected extends ExpenseReviewEvent {
  /// Rejects the expense.
  const ExpenseReviewRejected();
}
