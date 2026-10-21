part of 'bloc.dart';

/// Base of every action the expenses screen can dispatch.
sealed class ExpensesEvent {
  /// Allows the events to have const constructors.
  const ExpensesEvent();
}

/// The screen opened — load totals, the list and payouts.
final class ExpensesStarted extends ExpensesEvent {
  /// Fires the first load.
  const ExpensesStarted();
}

/// Pull-to-refresh — reload everything.
final class ExpensesRefreshed extends ExpensesEvent {
  /// Reloads while keeping the current rows visible.
  const ExpensesRefreshed();
}

/// The user picked another filter tab.
final class ExpensesFilterChanged extends ExpensesEvent {
  /// Index into `ExpensesBloc.filters`.
  final int filter;

  /// Carries the selected tab.
  const ExpensesFilterChanged(this.filter);
}

/// The user scrolled near the end of the list.
final class ExpensesMoreRequested extends ExpensesEvent {
  /// Loads the next page, if there is one.
  const ExpensesMoreRequested();
}

/// The boss marked an approved expense as paid out.
final class ExpensePaid extends ExpensesEvent {
  /// Id of the task the expense belongs to.
  final String taskId;

  /// Id of the expense.
  final String expenseId;

  /// Carries the expense to pay.
  const ExpensePaid(this.taskId, this.expenseId);
}

/// The boss marked a task reward as paid out.
final class ExpenseRewardPaid extends ExpensesEvent {
  /// Id of the completed task.
  final String taskId;

  /// Carries the task whose reward is paid.
  const ExpenseRewardPaid(this.taskId);
}
