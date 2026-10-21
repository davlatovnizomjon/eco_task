import '../../../domain/common/enums/expense_status.dart';
import '../../../domain/common/enums/task_priority.dart';
import '../../../domain/common/enums/task_status.dart';
import 'comment_model.dart';
import 'expense_model.dart';
import 'log_entry.dart';
import 'task_assignee.dart';
import 'user_ref.dart';

/// A unit of work given to one or more people.
class TaskModel {
  /// Human id such as `ECO-142`.
  final String id;

  /// Short title.
  final String title;

  /// Longer description; may be empty.
  final String description;

  /// Expected result, e.g. "50 ta ko'chat"; may be empty.
  final String expected;

  /// Topic label such as "Sotuv"; may be empty.
  final String category;

  /// The person who created it.
  final UserRef createdBy;

  /// Lifecycle state.
  final TaskStatus status;

  /// Importance.
  final TaskPriority priority;

  /// Deadline.
  final DateTime due;

  /// Reward promised for the whole task.
  final int reward;

  /// Number of attached files/photos.
  final int files;

  /// True once the reward was paid out.
  final bool isPaid;

  /// Result text a worker submitted for review; empty before that.
  final String result;

  /// When the result was submitted, if it was.
  final DateTime? submittedAt;

  /// People assigned, each with quota and progress.
  final List<TaskAssignee> assignees;

  /// Expenses entered against the task.
  final List<ExpenseModel> expenses;

  /// Discussion, oldest first.
  final List<CommentModel> comments;

  /// Activity log, newest first.
  final List<LogEntry> log;

  /// Builds a task from its parts.
  const TaskModel({
    required this.id,
    required this.title,
    required this.due,
    required this.createdBy,
    this.description = '',
    this.expected = '',
    this.category = '',
    this.status = TaskStatus.fresh,
    this.priority = TaskPriority.medium,
    this.reward = 0,
    this.files = 0,
    this.isPaid = false,
    this.result = '',
    this.submittedAt,
    this.assignees = const [],
    this.expenses = const [],
    this.comments = const [],
    this.log = const [],
  });

  /// Id as shown to people: human ids such as `ECO-142` as they are, a long
  /// backend UUID shortened to `#1A2B3C4D`.
  String get code => id.length > 12 ? '#${id.substring(0, 8).toUpperCase()}' : id;

  /// Parses the API object.
  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: '${json['id']}',
    title: '${json['title']}',
    description: '${json['description'] ?? ''}',
    expected: '${json['expected'] ?? ''}',
    category: '${json['category'] ?? ''}',
    createdBy: UserRef.fromJson(json['createdBy'] as Map<String, dynamic>),
    status: TaskStatus.fromJson(json['status']),
    priority: TaskPriority.fromJson(json['priority']),
    due: DateTime.parse('${json['due']}'),
    reward: (json['reward'] as num?)?.toInt() ?? 0,
    files: (json['files'] as num?)?.toInt() ?? 0,
    isPaid: json['isPaid'] as bool? ?? false,
    result: '${json['result'] ?? ''}',
    submittedAt: json['submittedAt'] == null ? null : DateTime.parse('${json['submittedAt']}'),
    assignees: [
      for (final a in (json['assignees'] as List? ?? const [])) TaskAssignee.fromJson(a as Map<String, dynamic>),
    ],
    expenses: [
      for (final e in (json['expenses'] as List? ?? const [])) ExpenseModel.fromJson(e as Map<String, dynamic>),
    ],
    comments: [
      for (final c in (json['comments'] as List? ?? const [])) CommentModel.fromJson(c as Map<String, dynamic>),
    ],
    log: [for (final l in (json['log'] as List? ?? const [])) LogEntry.fromJson(l as Map<String, dynamic>)],
  );

  /// Serializes the task.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'expected': expected,
    'category': category,
    'createdBy': createdBy.toJson(),
    'status': status.name,
    'priority': priority.name,
    'due': due.toIso8601String(),
    'reward': reward,
    'files': files,
    'isPaid': isPaid,
    'result': result,
    'submittedAt': submittedAt?.toIso8601String(),
    'assignees': [for (final a in assignees) a.toJson()],
    'expenses': [for (final e in expenses) e.toJson()],
    'comments': [for (final c in comments) c.toJson()],
    'log': [for (final l in log) l.toJson()],
  };

  /// Copy with the given fields replaced.
  TaskModel copyWith({
    String? title,
    String? description,
    String? expected,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? due,
    int? reward,
    bool? isPaid,
    String? result,
    DateTime? submittedAt,
    List<TaskAssignee>? assignees,
    List<ExpenseModel>? expenses,
    List<CommentModel>? comments,
    List<LogEntry>? log,
  }) => TaskModel(
    id: id,
    createdBy: createdBy,
    category: category,
    files: files,
    title: title ?? this.title,
    description: description ?? this.description,
    expected: expected ?? this.expected,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    due: due ?? this.due,
    reward: reward ?? this.reward,
    isPaid: isPaid ?? this.isPaid,
    result: result ?? this.result,
    submittedAt: submittedAt ?? this.submittedAt,
    assignees: assignees ?? this.assignees,
    expenses: expenses ?? this.expenses,
    comments: comments ?? this.comments,
    log: log ?? this.log,
  );

  /// Ids of everyone assigned.
  List<String> get assigneeIds => [for (final a in assignees) a.userId];

  /// Sum of all quotas.
  int get totalShare => assignees.fold(0, (sum, a) => sum + a.share);

  /// Sum of all completed pieces.
  int get totalDone => assignees.fold(0, (sum, a) => sum + a.done);

  /// 0..1 progress, or null for tasks without a quantity.
  double? get ratio => totalShare == 0 ? null : (totalDone / totalShare).clamp(0, 1).toDouble();

  /// True when the task is open and past its deadline.
  bool get isOverdue => status.isOpen && due.isBefore(DateTime.now());

  /// Whole days past the deadline, at least 1 for an overdue task.
  int get lateDays => DateTime.now().difference(due).inDays.clamp(1, 999);

  /// Sum of all entered expense amounts.
  int get enteredSum => expenses.fold(0, (sum, e) => sum + e.amount);

  /// Sum of the amounts the boss approved.
  int get approvedSum =>
      expenses.fold(0, (sum, e) => sum + (e.status == ExpenseStatus.approved ? e.approvedAmount : 0));

  /// True when every approved expense was paid out (vacuously true with none).
  bool get expensesPaid => expenses.every((e) => e.status != ExpenseStatus.approved || e.isPaid);

  /// True when [userId] is among the assignees.
  bool involves(String userId) => assignees.any((a) => a.userId == userId);

  /// The assignment record of [userId], or null when not assigned.
  TaskAssignee? assigneeOf(String userId) => assignees.where((a) => a.userId == userId).firstOrNull;
}
