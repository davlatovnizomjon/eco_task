import 'package:eco_task/domain/common/enums/expense_kind.dart';
import 'package:eco_task/domain/common/enums/expense_status.dart';
import 'package:eco_task/domain/common/enums/log_kind.dart';
import 'package:eco_task/domain/common/enums/notification_kind.dart';
import 'package:eco_task/domain/common/enums/task_priority.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/infrastructure/dto/models/app_user.dart';
import 'package:eco_task/infrastructure/dto/models/comment_model.dart';
import 'package:eco_task/infrastructure/dto/models/expense_model.dart';
import 'package:eco_task/infrastructure/dto/models/log_entry.dart';
import 'package:eco_task/infrastructure/dto/models/notification_model.dart';
import 'package:eco_task/infrastructure/dto/models/permissions_model.dart';
import 'package:eco_task/infrastructure/dto/models/person_stat.dart';
import 'package:eco_task/infrastructure/dto/models/request_model.dart';
import 'package:eco_task/infrastructure/dto/models/task_assignee.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';

import 'mock_seed.dart';

/// A scripted failure the mock backend raises; `MockDioClient` converts it to
/// the RFC 7807 shape the live API sends, so error handling is identical.
class MockFailure implements Exception {
  /// HTTP status the failure stands for.
  final int status;

  /// Human-readable `detail` text.
  final String detail;

  /// Builds a failure.
  const MockFailure(this.status, this.detail);
}

/// The in-memory "server" behind `MockDioClient`: it owns the seeded data,
/// applies every mutation and answers with the same JSON the live API would.
class MockStore {
  /// Private constructor — use [instance].
  MockStore._();

  /// The one in-memory backend of the running app.
  static final MockStore instance = MockStore._();

  /// Every account, seeded and newly opened.
  final List<AppUser> _users = [...MockSeed.users];

  /// Password per account id; seeded accounts all use `1234`.
  final Map<String, String> _passwords = {for (final u in MockSeed.users) u.id: '1234'};

  /// All tasks.
  final List<TaskModel> _tasks = MockSeed.tasks();

  /// All client requests.
  final List<RequestModel> _requests = MockSeed.requests();

  /// All inbox entries of all accounts.
  final List<NotificationModel> _inbox = MockSeed.notifications();

  /// Permission switches per staff id, created on first read.
  final Map<String, PermissionsModel> _permissions = {};

  /// Next numeric part of a new task id.
  int _taskSeq = 153;

  /// Next numeric part of a new notification id.
  int _noteSeq = 0;

  /// Every account (read-only view for sibling mock modules such as the chat).
  List<AppUser> get users => List.unmodifiable(_users);

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Account with [id], or throws 404.
  AppUser _user(String id) =>
      _users.firstWhere((u) => u.id == id, orElse: () => throw const MockFailure(404, 'Foydalanuvchi topilmadi.'));

  /// Task with [id], or throws 404.
  TaskModel _task(String id) =>
      _tasks.firstWhere((t) => t.id == id, orElse: () => throw MockFailure(404, 'Vazifa topilmadi: $id'));

  /// Replaces the stored task [id] with [change] applied to it; returns the result.
  TaskModel _update(String id, TaskModel Function(TaskModel) change) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index < 0) throw MockFailure(404, 'Vazifa topilmadi: $id');
    return _tasks[index] = change(_tasks[index]);
  }

  /// Staff the boss [me] supervises: everyone for admin, own team for manager.
  List<AppUser> _scopeWorkers(AppUser me) =>
      _users.where((u) => u.role == UserRole.worker && (me.role == UserRole.owner || u.team == me.team)).toList();

  /// Ids of the bosses that get review/expense/request news.
  List<String> get _bossIds => [
    for (final u in _users)
      if (u.role.isBoss) u.id,
  ];

  /// Tasks the account [me] is allowed to see.
  List<TaskModel> _visible(AppUser me) {
    switch (me.role) {
      case UserRole.owner:
        return [..._tasks];
      case UserRole.assistant:
        final ids = _scopeWorkers(me).map((u) => u.id).toSet();
        return _tasks.where((t) => t.assigneeIds.any(ids.contains)).toList();
      case UserRole.worker:
        return _tasks.where((t) => t.involves(me.id)).toList();
      case UserRole.client:
        return [];
    }
  }

  /// Money as the server words it inside notification texts: `1 000 $`.
  String _money(int value) {
    final digits = value.toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(' ');
      out.write(digits[i]);
    }
    return '$out \$';
  }

  /// Appends an inbox entry of [kind] for every id in [to].
  void _notify(NotificationKind kind, Iterable<String> to, {List<String> t = const [], List<String> b = const []}) {
    final now = DateTime.now();
    for (final id in to.toSet()) {
      _inbox.insert(
        0,
        NotificationModel(id: 'n${_noteSeq++}', userId: id, kind: kind, at: now, titleArgs: t, bodyArgs: b),
      );
    }
  }

  /// A log line authored by [me] right now.
  LogEntry _log(LogKind kind, AppUser me, [List<String> args = const []]) =>
      LogEntry(kind: kind, user: me.ref, at: DateTime.now(), args: args);

  /// Resolves the `[{userId, share}]` list of a task body into assignees.
  List<TaskAssignee> _assignees(Map<String, dynamic> body) => [
    for (final a in (body['assignees'] as List))
      TaskAssignee(user: _user('${(a as Map)['userId']}').ref, share: _int(a['share'], 0)),
  ];

  /// Reads an int query/body value with a default.
  int _int(Object? value, int fallback) => value is num ? value.toInt() : int.tryParse('${value ?? ''}') ?? fallback;

  /// Slices [items] into the requested page and wraps it with paging meta.
  Map<String, dynamic> _page(List<Map<String, dynamic>> items, Map<String, dynamic> query) {
    final size = _int(query['pageSize'], 20);
    final page = _int(query['page'], 1);
    final last = items.isEmpty ? 1 : (items.length / size).ceil();
    final from = ((page - 1) * size).clamp(0, items.length);
    final to = (from + size).clamp(0, items.length);
    return {'items': items.sublist(from, to), 'page': page, 'lastPage': last, 'total': items.length};
  }

  // ─── Auth & users ─────────────────────────────────────────────────────────

  /// Checks the credentials and returns `{token, user}`, or throws 401.
  Map<String, dynamic> login(String login, String password) {
    final id = login.trim().toLowerCase();
    final hit = _users.where((u) => u.id == id && _passwords[u.id] == password).firstOrNull;
    if (hit == null) throw const MockFailure(401, 'Login yoki parol noto‘g‘ri.');
    return {'token': 'mock-token-${hit.id}', 'user': hit.toJson()};
  }

  /// Account behind a mock bearer token, or null when it is unknown.
  AppUser? userForToken(String token) {
    final id = token.replaceFirst('mock-token-', '');
    return _users.where((u) => u.id == id).firstOrNull;
  }

  /// First seeded account with [role]; stands in for a live account when the
  /// real backend lacks an endpoint and the mock answers instead.
  AppUser? accountForRole(UserRole role) => _users.where((u) => u.role == role).firstOrNull;

  /// Paged directory of staff (`role=staff`) or clients (`role=client`).
  Map<String, dynamic> usersPage(AppUser me,Map<String, dynamic> query) {
    final q = '${query['q'] ?? ''}'.toLowerCase();
    final clients = query['role'] == 'client';
    final source = clients
        ? _users.where((u) => u.role == UserRole.client)
        : _users.where(
            (u) =>
                (u.role == UserRole.worker || u.role == UserRole.assistant) &&
                (me.role == UserRole.owner || u.team == me.team),
          );
    final list = source.where((u) => q.isEmpty || '${u.name} ${u.phone} ${u.team}'.toLowerCase().contains(q)).toList();
    return _page([
      for (final u in list)
        u
            .withActiveCount(
              clients
                  ? _requests.where((r) => r.client.id == u.id && !r.status.isDone).length
                  : _tasks.where((t) => t.status.isOpen && t.involves(u.id)).length,
            )
            .toJson(),
    ], query);
  }

  /// One account with its directory counter.
  Map<String, dynamic> user(String id) {
    final u = _user(id);
    return u.withActiveCount(_tasks.where((t) => t.status.isOpen && t.involves(u.id)).length).toJson();
  }

  /// Opens a new account from `{id, name, phone, role, team, password}`.
  Map<String, dynamic> addUser(Map<String, dynamic> body) {
    final id = '${body['id']}'.trim().toLowerCase();
    if (_users.any((u) => u.id == id)) throw const MockFailure(409, 'Bu login band. Boshqasini tanlang.');
    final created = AppUser(
      id: id,
      name: '${body['name']}',
      role: UserRole.fromJson(body['role']),
      phone: '${body['phone'] ?? ''}',
      team: '${body['team'] ?? ''}',
      color: _users.length % 6,
    );
    _users.add(created);
    _passwords[id] = '${body['password']}';
    return created.toJson();
  }

  /// Permission switches of staff [id].
  Map<String, dynamic> permissions(String id) {
    final u = _user(id);
    return (_permissions[id] ??= PermissionsModel(
      userId: id,
      role: u.role,
      flags: const {
        'create': true,
        'reward': true,
        'approve': true,
        'editOthers': false,
        'approveExpense': true,
        'viewPayments': false,
      },
    )).toJson();
  }

  /// Stores new `{role, flags}` for staff [id].
  Map<String, dynamic> savePermissions(String id, Map<String, dynamic> body) {
    final current = PermissionsModel.fromJson(permissions(id));
    final next = current.copyWith(
      role: UserRole.fromJson(body['role']),
      flags: {for (final e in ((body['flags'] as Map?) ?? const {}).entries) '${e.key}': e.value == true},
    );
    _permissions[id] = next;
    return next.toJson();
  }

  // ─── Tasks ────────────────────────────────────────────────────────────────

  /// Paged task list honouring `group`, `status`, `late`, `who`, `due`, `q`, `sort`.
  Map<String, dynamic> tasksPage(AppUser me, Map<String, dynamic> query) {
    final q = '${query['q'] ?? ''}'.toLowerCase();
    final statuses = '${query['status'] ?? ''}'.split(',').where((s) => s.isNotEmpty).map(TaskStatus.fromJson).toSet();
    final list = _visible(me).where((t) {
      if (query['group'] == 'active' && !(t.status.isOpen || t.status == TaskStatus.rev)) return false;
      if (query['group'] == 'history' && !t.status.isClosed) return false;
      if (statuses.isNotEmpty && !statuses.contains(t.status)) return false;
      if (query['late'] == '1' && !t.isOverdue) return false;
      if (query['who'] != null && !t.involves('${query['who']}')) return false;
      final days = DateTime(
        t.due.year,
        t.due.month,
        t.due.day,
      ).difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays;
      if (query['due'] == 'today' && days != 0) return false;
      if (query['due'] == 'week' && (days < 0 || days > 7)) return false;
      if (q.isNotEmpty &&
          !('${t.id} ${t.title} ${t.assigneeIds.map((a) => _user(a).name).join(' ')}').toLowerCase().contains(q))
        return false;
      return true;
    }).toList();
    list.sort(switch ('${query['sort']}') {
      'priority' => (a, b) => a.priority.index.compareTo(b.priority.index),
      'created' => (a, b) => b.id.compareTo(a.id),
      _ => (a, b) => a.due.compareTo(b.due),
    });
    return _page([for (final t in list) t.toJson()], query);
  }

  /// Tasks whose deadline falls into `month=YYYY-MM`, for the calendar.
  List<Map<String, dynamic>> calendar(AppUser me, Map<String, dynamic> query) {
    final parts = '${query['month']}'.split('-');
    final year = int.tryParse(parts.first) ?? DateTime.now().year;
    final month = parts.length > 1 ? int.tryParse(parts[1]) ?? DateTime.now().month : DateTime.now().month;
    return [
      for (final t in _visible(me))
        if (t.due.year == year && t.due.month == month) t.toJson(),
    ];
  }

  /// One task, or 404.
  Map<String, dynamic> task(String id) => _task(id).toJson();

  /// Creates a task from `{title, due, priority, reward, description, expected, assignees}`.
  Map<String, dynamic> createTask(AppUser me, Map<String, dynamic> body) {
    final task = TaskModel(
      id: 'ECO-${_taskSeq++}',
      title: '${body['title']}',
      due: DateTime.parse('${body['due']}'),
      createdBy: me.ref,
      priority: TaskPriority.fromJson(body['priority']),
      reward: _int(body['reward'], 0),
      description: '${body['description'] ?? ''}',
      expected: '${body['expected'] ?? ''}',
      assignees: _assignees(body),
      log: [_log(LogKind.created, me)],
    );
    _tasks.insert(0, task);
    _notify(NotificationKind.newTask, task.assigneeIds.where((id) => id != me.id), b: [me.firstName, task.title]);
    return task.toJson();
  }

  /// Edits a task from the same body as [createTask]; progress is preserved.
  Map<String, dynamic> editTask(String id, Map<String, dynamic> body) => _update(id, (t) {
    final incoming = _assignees(body);
    return t.copyWith(
      title: '${body['title']}',
      due: DateTime.parse('${body['due']}'),
      priority: TaskPriority.fromJson(body['priority']),
      reward: _int(body['reward'], 0),
      description: '${body['description'] ?? ''}',
      expected: '${body['expected'] ?? ''}',
      assignees: [
        for (final a in incoming) TaskAssignee(user: a.user, share: a.share, done: t.assigneeOf(a.userId)?.done ?? 0),
      ],
    );
  }).toJson();

  /// Cancels a task.
  Map<String, dynamic> cancelTask(AppUser me, String id) =>
      _update(id, (t) => t.copyWith(status: TaskStatus.canc, log: [_log(LogKind.canceled, me), ...t.log])).toJson();

  /// Records `{done, cant, note}` progress of [me] on a task.
  Map<String, dynamic> progress(AppUser me, String id, Map<String, dynamic> body) => _update(id, (t) {
    final done = _int(body['done'], 0);
    final cant = body['cant'] == true;
    final note = '${body['note'] ?? ''}'.trim();
    final first = t.status == TaskStatus.fresh;
    return t.copyWith(
      status: cant ? TaskStatus.fail : (first ? TaskStatus.prog : t.status),
      assignees: [for (final a in t.assignees) a.userId == me.id ? a.withDone(done) : a],
      comments: note.isEmpty ? null : [...t.comments, CommentModel(user: me.ref, text: note, at: DateTime.now())],
      log: [
        _log(LogKind.progress, me, ['$done']),
        if (first) _log(LogKind.started, me),
        ...t.log,
      ],
    );
  }).toJson();

  /// Adds `{text}` as a comment of [me] and tells the other participants.
  Map<String, dynamic> addComment(AppUser me, String id, Map<String, dynamic> body) => _update(id, (t) {
    final text = '${body['text']}'.trim();
    _notify(
      NotificationKind.comment,
      t.assigneeIds.followedBy(_bossIds).where((x) => x != me.id),
      t: [me.firstName],
      b: [text],
    );
    return t.copyWith(
      comments: [
        ...t.comments,
        CommentModel(user: me.ref, text: text, at: DateTime.now()),
      ],
    );
  }).toJson();

  /// Adds the expense `{amount, kind, note, hasReceipt}` of [me] to a task.
  Map<String, dynamic> addExpense(AppUser me, String id, Map<String, dynamic> body) => _update(id, (t) {
    final amount = _int(body['amount'], 0);
    final kind = ExpenseKind.fromJson(body['kind']);
    final note = '${body['note'] ?? ''}'.trim();
    final expense = ExpenseModel(
      id: 'e${DateTime.now().microsecondsSinceEpoch}',
      user: me.ref,
      note: note.isEmpty ? kind.name : note,
      amount: amount,
      kind: kind,
      hasReceipt: body['hasReceipt'] == true,
      at: DateTime.now(),
    );
    _notify(NotificationKind.expense, _bossIds, t: [_money(amount)], b: [expense.note, t.id]);
    return t.copyWith(
      expenses: [...t.expenses, expense],
      log: [
        _log(LogKind.expense, me, [_money(amount)]),
        ...t.log,
      ],
    );
  }).toJson();

  /// Submits `{text}` as the result of a task for review.
  Map<String, dynamic> submit(AppUser me, String id, Map<String, dynamic> body) => _update(id, (t) {
    _notify(NotificationKind.review, _bossIds, b: [me.firstName, t.title]);
    return t.copyWith(
      status: TaskStatus.rev,
      result: '${body['text'] ?? ''}',
      submittedAt: DateTime.now(),
      log: [_log(LogKind.submitted, me), ...t.log],
    );
  }).toJson();

  /// Approves the submitted result.
  Map<String, dynamic> approve(AppUser me, String id) => _update(id, (t) {
    _notify(NotificationKind.approved, t.assigneeIds, b: [t.id, _money(t.reward)]);
    return t.copyWith(status: TaskStatus.done, log: [_log(LogKind.done, me), ...t.log]);
  }).toJson();

  /// Returns a task for rework with `{reason, extend}`.
  Map<String, dynamic> returnTask(AppUser me, String id, Map<String, dynamic> body) => _update(id, (t) {
    _notify(NotificationKind.returned, t.assigneeIds, b: [t.title, '${body['reason'] ?? ''}']);
    return t.copyWith(
      status: TaskStatus.prog,
      due: body['extend'] == true ? t.due.add(const Duration(days: 2)) : null,
      log: [_log(LogKind.returned, me), ...t.log],
    );
  }).toJson();

  /// Marks the reward of a task as paid out.
  Map<String, dynamic> payReward(String id) => _update(id, (t) => t.copyWith(isPaid: true)).toJson();

  // ─── Expenses ─────────────────────────────────────────────────────────────

  /// Rows of the expenses list matching `filter` (`pending|approved|rejected|paid`).
  List<(TaskModel, ExpenseModel)> _expenseRows(AppUser me, String? filter) {
    bool match(ExpenseModel e) => switch (filter) {
      'pending' => e.status == ExpenseStatus.pending,
      'approved' => e.status == ExpenseStatus.approved && !e.isPaid,
      'rejected' => e.status == ExpenseStatus.rejected,
      'paid' => e.isPaid,
      _ => true,
    };
    return [
      for (final t in _visible(me))
        for (final e in t.expenses)
          if (match(e)) (t, e),
    ]..sort((a, b) => b.$2.at.compareTo(a.$2.at));
  }

  /// Paged expense rows for the `filter` tab.
  Map<String, dynamic> expenses(AppUser me, Map<String, dynamic> query) => _page([
    for (final (t, e) in _expenseRows(me, query['filter'] as String?))
      {'taskId': t.id, 'taskTitle': t.title, 'expense': e.toJson()},
  ], query);

  /// Money totals and per-filter counters of the boss's scope.
  Map<String, dynamic> expensesSummary(AppUser me) {
    final all = _expenseRows(me, null);
    final rewardsPaid = _visible(me).where((t) => t.isPaid).fold(0, (sum, t) => sum + t.reward);
    int count(String f) => _expenseRows(me, f).length;
    return {
      'entered': all.fold(0, (s, r) => s + r.$2.amount),
      'approved': all.fold(0, (s, r) => s + (r.$2.status == ExpenseStatus.approved ? r.$2.approvedAmount : 0)),
      'rejected': all.fold(0, (s, r) => s + (r.$2.status == ExpenseStatus.rejected ? r.$2.amount : 0)),
      'paidOut': all.fold(0, (s, r) => s + (r.$2.isPaid ? r.$2.approvedAmount : 0)) + rewardsPaid,
      'counts': {
        'pending': count('pending'),
        'approved': count('approved'),
        'rejected': count('rejected'),
        'paid': count('paid'),
      },
    };
  }

  /// Approves expense [expenseId] for `amount`, or rejects it when `amount` is absent.
  Map<String, dynamic> reviewExpense(String taskId, String expenseId, Map<String, dynamic> body) =>
      _update(taskId, (t) {
        final amount = body['amount'] == null ? null : _int(body['amount'], 0);
        final target = t.expenses.firstWhere(
          (e) => e.id == expenseId,
          orElse: () => throw const MockFailure(404, 'Xarajat topilmadi.'),
        );
        if (amount != null && (amount <= 0 || amount > target.amount))
          throw const MockFailure(400, 'Tasdiqlanadigan summa noto‘g‘ri.');
        if (amount != null)
          _notify(NotificationKind.expenseApproved, [target.user.id], t: [_money(amount)], b: [_money(target.amount)]);
        return t.copyWith(
          expenses: [
            for (final e in t.expenses)
              e.id == expenseId
                  ? e.copyWith(
                      status: amount == null ? ExpenseStatus.rejected : ExpenseStatus.approved,
                      approvedAmount: amount ?? 0,
                    )
                  : e,
          ],
        );
      }).toJson();

  /// Marks expense [expenseId] as paid out.
  Map<String, dynamic> payExpense(String taskId, String expenseId) => _update(
    taskId,
    (t) => t.copyWith(expenses: [for (final e in t.expenses) e.id == expenseId ? e.copyWith(isPaid: true) : e]),
  ).toJson();

  // ─── Inbox ────────────────────────────────────────────────────────────────

  /// Paged inbox of [me] for the `group` tab (`all|unread|review|deadlines|expenses`).
  Map<String, dynamic> notifications(AppUser me, Map<String, dynamic> query) {
    final group = '${query['group'] ?? 'all'}';
    final list = _inbox.where((n) {
      if (n.userId != me.id) return false;
      return switch (group) {
        'unread' => !n.isRead,
        'review' => n.kind.group == NotificationGroup.review,
        'deadlines' => n.kind.group == NotificationGroup.deadlines,
        'expenses' => n.kind.group == NotificationGroup.expenses,
        _ => true,
      };
    }).toList()..sort((a, b) => b.at.compareTo(a.at));
    final page = _page([for (final n in list) n.toJson()], query);
    return {...page, 'unread': _inbox.where((n) => n.userId == me.id && !n.isRead).length};
  }

  /// Marks `{id}` (or every entry when absent) of [me] as read.
  void markRead(AppUser me, Map<String, dynamic> body) {
    for (var i = 0; i < _inbox.length; i++) {
      final n = _inbox[i];
      if (n.userId == me.id && (body['id'] == null || body['id'] == n.id)) _inbox[i] = n.asRead();
    }
  }

  // ─── Aggregates ───────────────────────────────────────────────────────────

  /// Counters of one worker over [scope].
  PersonStat _stat(AppUser worker, List<TaskModel> scope) {
    final mine = scope.where((t) => t.involves(worker.id)).toList();
    final done = mine.where((t) => t.status == TaskStatus.done).toList();
    final late = mine.where((t) => t.isOverdue).map((t) => t.lateDays);
    final onTime = done
        .where((t) => !(t.log.where((l) => l.kind == LogKind.done).firstOrNull?.at ?? t.due).isAfter(t.due))
        .length;
    return PersonStat(
      user: worker,
      done: done.length,
      total: mine.length,
      lateDays: late.isEmpty ? 0 : late.reduce((a, b) => a > b ? a : b),
      onTime: onTime,
    );
  }

  /// Numbers of the boss dashboard.
  Map<String, dynamic> dashboard(AppUser me) {
    final tasks = _visible(me);
    final today = DateTime.now();
    final endOfToday = DateTime(today.year, today.month, today.day, 23, 59);
    final due = tasks.where((t) => t.status.isOpen && !t.due.isAfter(endOfToday)).toList()
      ..sort((a, b) => a.due.compareTo(b.due));
    return {
      'inReview': tasks.where((t) => t.status == TaskStatus.rev).length,
      'overdue': tasks.where((t) => t.isOverdue).length,
      'pendingExpenses': _expenseRows(me, 'pending').length,
      'dueToday': [for (final t in due.take(3)) t.toJson()],
      'team': [for (final w in _scopeWorkers(me).take(4)) _stat(w, tasks).toJson()],
    };
  }

  /// Aggregated report for `period` (`week|month|quarter`).
  Map<String, dynamic> reports(AppUser me, Map<String, dynamic> query) {
    final all = _visible(me);
    final days = switch ('${query['period']}') {
      'week' => 7,
      'quarter' => 120,
      _ => 31,
    };
    final tasks = all.where((t) => t.due.difference(DateTime.now()).inDays.abs() <= days).toList();
    final doneNow = tasks.where((t) => t.status == TaskStatus.done).length;
    return {
      'counts': {for (final s in TaskStatus.values) s.name: tasks.where((t) => t.status == s).length},
      'overdue': tasks.where((t) => t.isOverdue).length,
      'lateDelivered': tasks
          .where((t) => t.status == TaskStatus.rev && (t.submittedAt?.isAfter(t.due) ?? false))
          .length,
      'weekly': [5, 8, 7, doneNow + 2],
      'rewards': tasks.where((t) => t.status == TaskStatus.done).fold(0, (s, t) => s + t.reward),
      'expenses': tasks.fold(0, (s, t) => s + t.approvedSum),
      'paid': tasks.where((t) => t.isPaid).fold(0, (s, t) => s + t.reward),
      'people': [for (final w in _scopeWorkers(me)) _stat(w, tasks).toJson()],
    };
  }

  /// Numbers of the profile screen for [me].
  Map<String, dynamic> profileSummary(AppUser me) {
    final tasks = _visible(me);
    final done = tasks.where((t) => t.status == TaskStatus.done).toList();
    return {
      'activeTasks': tasks.where((t) => t.status.isOpen || t.status == TaskStatus.rev).length,
      'doneTasks': done.length,
      'monthReward': done.fold(0, (s, t) => s + t.reward),
      'paidReward': done.where((t) => t.isPaid).fold(0, (s, t) => s + t.reward),
      'pendingExpenses': me.role.isBoss ? _expenseRows(me, 'pending').length : 0,
      'teamSize': me.role.isBoss ? _scopeWorkers(me).length : 0,
    };
  }
}
