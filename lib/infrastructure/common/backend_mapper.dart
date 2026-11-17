/// Pure JSON translation between the shapes the app's DTOs parse and the shapes
/// the Django backend (`backend/`, documented at `/api/docs/`) speaks.
///
/// Everything here is a stateless function over decoded JSON, so the mapping is
/// testable without a network. The only place that calls it is
/// `BackendDioClient`; repositories, blocs and screens never see backend JSON.
abstract final class BackendMapper {
  /// Backend task status → app `TaskStatus` name.
  static const _taskStatus = {
    'OPEN': 'fresh',
    'IN_PROGRESS': 'prog',
    'REVIEW': 'rev',
    'COMPLETED': 'done',
    'FAILED': 'fail',
    'CANCELED': 'canc',
  };

  /// Backend statuses of the "active" task list group.
  static const activeStatuses = 'OPEN,IN_PROGRESS,REVIEW';

  /// Backend statuses of the "history" task list group.
  static const closedStatuses = 'COMPLETED,FAILED,CANCELED';

  /// App `TaskStatus` name → backend status.
  static String backendStatus(String appStatus) =>
      _taskStatus.entries.firstWhere((e) => e.value == appStatus, orElse: () => const MapEntry('OPEN', '')).key;

  /// Casts a decoded JSON object.
  static Map<String, dynamic> _map(Object? json) => (json as Map).cast<String, dynamic>();

  /// Avatar palette slot derived from the numeric account id (the backend has no colors).
  static int _color(Object? id) => (int.tryParse('$id') ?? 0) % 8;

  /// Display name of a backend user: full name, else the login.
  static String _name(Map<String, dynamic> user) {
    final full = '${user['full_name'] ?? ''}'.trim();
    return full.isNotEmpty ? full : '${user['username'] ?? user['id']}';
  }

  /// `User` / `UserBrief` → app `AppUser` JSON.
  static Map<String, dynamic> user(Object? json) {
    final u = _map(json);
    return {
      'id': '${u['id']}',
      'name': _name(u),
      'phone': u['phone'] ?? '',
      'role': u['role'],
      'color': _color(u['id']),
      'team': u['address'] ?? '',
      'isOrg': u['is_org'] ?? false,
      'contactPerson': u['contact_person'] ?? '',
      'note': u['note'] ?? '',
      'avatarUrl': u['avatar_url'] ?? '',
    };
  }

  /// `User` / `UserBrief` → app `UserRef` JSON.
  static Map<String, dynamic> ref(Object? json) {
    final u = _map(json);
    return {
      'id': '${u['id']}',
      'name': _name(u),
      'color': _color(u['id']),
      if (u['role'] != null) 'role': u['role'],
      'avatarUrl': u['avatar_url'] ?? '',
    };
  }

  /// `{token, refresh, user}` of `auth/login/` → app `AuthUser` JSON.
  static Map<String, dynamic> session(Object? json) {
    final body = _map(json);
    return {'token': body['token'], 'refresh': body['refresh'], 'user': user(body['user'])};
  }

  /// A DRF page `{count, results}` → app `PagedList` JSON, mapping every row with [item].
  static Map<String, dynamic> page(
    Object? json, {
    required int page,
    required int pageSize,
    required Object? Function(Object?) item,
  }) {
    final body = _map(json);
    final total = (body['count'] as num?)?.toInt() ?? 0;
    return {
      'items': [for (final row in body['results'] as List) item(row)],
      'page': page,
      'lastPage': total == 0 ? 1 : (total / pageSize).ceil(),
      'total': total,
    };
  }

  /// Backend `Task` (+ optional history and comments of the detail view) → app `TaskModel` JSON.
  static Map<String, dynamic> task(
    Object? json, {
    List<dynamic> history = const [],
    List<dynamic> comments = const [],
  }) {
    final t = _map(json);
    final rows = [for (final h in history) _map(h)]
      ..sort((a, b) => '${b['created_at']}'.compareTo('${a['created_at']}'));
    final submitted = rows.where((h) => h['to_status'] == 'REVIEW').firstOrNull;
    final value = double.tryParse('${t['agreed_value'] ?? ''}');
    return {
      'id': '${t['id']}',
      'title': t['title'],
      'description': t['description'] ?? '',
      'createdBy': ref(t['creator']),
      'status': _taskStatus['${t['status']}'] ?? 'fresh',
      'priority': '${t['priority']}'.toLowerCase(),
      'due': '${t['due_date'] ?? t['created_at']}',
      'reward': value?.round() ?? 0,
      'result': submitted == null ? '' : submitted['reason'] ?? '',
      'submittedAt': submitted?['created_at'],
      'assignees': [
        for (final a in (t['assignees'] as List? ?? const [])) {'user': ref(a), 'share': 0, 'done': 0},
      ],
      'comments': [
        for (final c in comments)
          {'user': ref(_map(c)['author']), 'text': _map(c)['body'], 'at': _map(c)['created_at']},
      ],
      'log': [for (final h in rows) logEntry(h)],
      'client': '${t['client_name'] ?? ''}'.isNotEmpty
          ? t['client_name']
          : (t['client'] == null ? '' : _name(_map(t['client']))),
      'clientIsOrg': t['client_is_org'] ?? false,
      'address': t['address'] ?? '',
      'remindAt': t['remind_at'],
      'createdAt': t['created_at'],
      'currency': '${t['currency'] ?? 'USD'}'.toLowerCase(),
      'attachments': t['attachments'] ?? const [],
    };
  }

  /// Backend statistics answer → app `StatsReport` JSON (snake_case people rows become the app's names).
  static Map<String, dynamic> stats(Object? json) {
    final s = _map(json);
    Map<String, dynamic> person(Object? p) {
      final r = _map(p);
      return {'user': ref(r['user']), 'isOrg': r['is_org'] ?? false, 'date': r['date'], 'a': r['a'], 'b': r['b']};
    }

    num n(Object? v) => v is num ? v : (double.tryParse('${v ?? 0}') ?? 0);
    return {
      'total': n(s['total']),
      'delta': s['delta'],
      'previous': n(s['previous']),
      'a': n(s['a']),
      'b': n(s['b']),
      'split': s['split'] ?? const [],
      'bars': [for (final v in (s['bars'] as List? ?? const [])) n(v)],
      'plan': n(s['plan']),
      'facts': [for (final v in (s['facts'] as List? ?? const [])) n(v)],
      'people': [for (final p in (s['people'] as List? ?? const [])) person(p)],
      'everyone': [for (final p in (s['everyone'] as List? ?? const [])) person(p)],
    };
  }

  /// Backend dashboard answer plus the head counts → app `DashboardSummary` JSON.
  static Map<String, dynamic> dashboard(Object? json) {
    final d = _map(json);
    return {
      'inReview': d['in_review'],
      'overdue': d['overdue'],
      'pendingExpenses': 0,
      'pendingNew': d['pending_new'],
      'pendingClient': d['pending_client'],
      'dueToday': [for (final t in (d['due_today'] as List? ?? const [])) task(t)],
      'team': [
        for (final row in (d['team'] as List? ?? const []))
          {
            'user': user(_map(row)['user']),
            'done': _map(row)['done'],
            'total': _map(row)['total'],
            'lateDays': 0,
            'onTime': _map(row)['done'],
          },
      ],
    };
  }

  /// One backend `TaskHistory` row → app `LogEntry` JSON.
  static Map<String, dynamic> logEntry(Map<String, dynamic> h) {
    final from = '${h['from_status']}';
    final kind = switch ('${h['to_status']}') {
      'OPEN' => 'created',
      'IN_PROGRESS' => from == 'REVIEW' ? 'returned' : 'started',
      'REVIEW' => 'submitted',
      'COMPLETED' => 'done',
      'FAILED' => 'failed',
      _ => 'canceled',
    };
    return {'kind': kind, 'user': ref(h['actor']), 'at': h['created_at'], 'args': const <String>[]};
  }

  /// Backend `Notification` → app `NotificationModel` JSON.
  static Map<String, dynamic> notification(Object? json, {required String userId}) {
    final n = _map(json);
    final title = '${n['title']}';
    final (kind, args) = switch ('${n['kind']}') {
      'task.assigned' => ('taskAssigned', [title.replaceFirst(RegExp(r'^You were assigned:\s*'), '')]),
      'task.status' => ('taskStatus', _statusArgs(title)),
      'chat.message' => ('chatMessage', [title.replaceFirst(RegExp(r'^New message from\s*'), '')]),
      _ => ('taskStatus', [title, '']),
    };
    return {
      'id': '${n['id']}',
      'userId': userId,
      'kind': kind,
      'at': n['created_at'],
      'titleArgs': args,
      'bodyArgs': args,
      'isRead': n['read_at'] != null,
    };
  }

  /// Splits the backend sentence `"<title>: OPEN -> REVIEW"` into `[title, new status key]`.
  static List<String> _statusArgs(String title) {
    final match = RegExp(r'^(.*): (\w+) -> (\w+)$').firstMatch(title);
    if (match == null) return [title, ''];
    return [match.group(1)!, _taskStatus[match.group(3)] ?? ''];
  }

  /// `YYYY-MM-DD` of [day], the form the backend date filters expect.
  static String date(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}
