import '../../../domain/common/enums/task_due_filter.dart';
import '../../../domain/common/enums/task_sort.dart';
import '../../../domain/common/enums/task_status.dart';

/// Which slice of the task list to load: the filters of one list screen.
class TaskQuery {
  /// `active` (open + in review), `history` (closed) or null for everything.
  final String? group;

  /// Free-text search over id, title and assignee names.
  final String search;

  /// Statuses to keep; empty keeps all.
  final Set<TaskStatus> statuses;

  /// Keep only overdue tasks.
  final bool overdueOnly;

  /// Keep only tasks involving this person; null keeps all.
  final String? who;

  /// Deadline window.
  final TaskDueFilter due;

  /// Sort order.
  final TaskSort sort;

  /// Builds a query; the defaults load everything, soonest first.
  const TaskQuery({
    this.group,
    this.search = '',
    this.statuses = const {},
    this.overdueOnly = false,
    this.who,
    this.due = TaskDueFilter.any,
    this.sort = TaskSort.due,
  });

  /// Copy with the given fields replaced; pass `clearWho` to drop [who].
  TaskQuery copyWith({
    String? search,
    Set<TaskStatus>? statuses,
    bool? overdueOnly,
    String? who,
    bool clearWho = false,
    TaskDueFilter? due,
    TaskSort? sort,
  }) => TaskQuery(
    group: group,
    search: search ?? this.search,
    statuses: statuses ?? this.statuses,
    overdueOnly: overdueOnly ?? this.overdueOnly,
    who: clearWho ? null : (who ?? this.who),
    due: due ?? this.due,
    sort: sort ?? this.sort,
  );

  /// Number of active filters, shown as the filter button's badge.
  int get activeCount =>
      (statuses.isEmpty ? 0 : 1) + (overdueOnly ? 1 : 0) + (who == null ? 0 : 1) + (due == TaskDueFilter.any ? 0 : 1);

  /// Query parameters of the `tasks` endpoint for the given [page].
  Map<String, dynamic> toParams(int page, int pageSize) => {
    'page': page,
    'pageSize': pageSize,
    if (group != null) 'group': group,
    if (search.isNotEmpty) 'q': search,
    if (statuses.isNotEmpty) 'status': statuses.map((s) => s.name).join(','),
    if (overdueOnly) 'late': '1',
    if (who != null) 'who': who,
    if (due != TaskDueFilter.any) 'due': due.name,
    'sort': sort.name,
  };

  /// Key under which the first page of this query is cached.
  String get cacheKey => 'tasks|${toParams(1, 0)}';
}
