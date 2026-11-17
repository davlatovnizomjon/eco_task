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

  /// Ids of the uploaded files the task should hold after saving (photos and documents).
  final List<int> attachmentIds;

  /// Client the task is done for; empty for an internal task.
  final String client;

  /// True when [client] is an organization.
  final bool clientIsOrg;

  /// Place the work happens at.
  final String address;

  /// Currency of [reward]: `uzs` or `usd`.
  final String currency;

  /// Builds a draft from its parts.
  const TaskDraft({
    required this.title,
    required this.due,
    required this.assignees,
    this.priority = TaskPriority.medium,
    this.reward = 0,
    this.description = '',
    this.expected = '',
    this.client = '',
    this.clientIsOrg = false,
    this.address = '',
    this.currency = 'usd',
    this.attachmentIds = const [],
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
    'client': client,
    'clientIsOrg': clientIsOrg,
    'address': address,
    'currency': currency,
    'attachmentIds': attachmentIds,
  };
}
