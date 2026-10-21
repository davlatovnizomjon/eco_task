import 'expense_model.dart';

/// An expense together with the task it belongs to (expenses list rows).
class ExpenseEntry {
  /// Id of the task.
  final String taskId;

  /// Title of the task.
  final String taskTitle;

  /// The expense.
  final ExpenseModel expense;

  /// Builds an entry from its parts.
  const ExpenseEntry({required this.taskId, required this.taskTitle, required this.expense});

  /// Parses the API object.
  factory ExpenseEntry.fromJson(Map<String, dynamic> json) => ExpenseEntry(
    taskId: '${json['taskId']}',
    taskTitle: '${json['taskTitle']}',
    expense: ExpenseModel.fromJson(json['expense'] as Map<String, dynamic>),
  );
}
