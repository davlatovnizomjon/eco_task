import '../../../domain/common/enums/task_priority.dart';
import 'task_assignee.dart';

/// What the create/edit form sends: a task without server-owned fields.
class TaskDraft {
  /// Short title.
  final String title;

  /// Deadline.
  final DateTime due;

  /// Importance.
  final TaskPriority priority;

  /// Reward for the whole task.
  final int reward;

  /// Longer description; may be empty.
  final String description;

  /// Expected result; may be empty.
  final String expected;

  /// People with their quotas.
  final List<TaskAssignee> assignees;

  /// Builds a draft from its parts.
  const TaskDraft({
    required this.title,
    required this.due,
    required this.assignees,
    this.priority = TaskPriority.medium,
    this.reward = 0,
    this.description = '',
    this.expected = '',
  });

  /// Request body of `POST tasks` / `PUT tasks/{id}`.
  Map<String, dynamic> toJson() => {
    'title': title,
    'due': due.toIso8601String(),
    'priority': priority.name,
    'reward': reward,
    'description': description,
    'expected': expected,
    'assignees': [for (final a in assignees) a.toJson()],
  };
}
