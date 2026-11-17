import 'package:dio/dio.dart';

import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/helpers/response_helper.dart';

import 'backend_mapper.dart';
import 'dio_client.dart';
import 'mock_dio_client.dart';
import 'mock_json_data/mock_store.dart';

/// The live client: it speaks to the Django backend while the repositories
/// keep calling the app's own paths and bodies (`tasks/{id}/approve`, `login`,
/// ...). Each call is translated here — paths, query names, status words and
/// response shapes — through [BackendMapper], so nothing above this class
/// knows which backend answers.
///
/// The chat endpoints already use the backend's own shape and go straight
/// through. Features the backend does not have yet (expenses, client
/// requests, dashboard, reports, profile numbers) are answered by the
/// in-memory mock store, acting as the signed-in role, so those screens stay
/// usable until the matching endpoints exist.
class BackendDioClient extends DioClient {
  /// Mock backend for the features the live API lacks.
  late final MockDioClient _fallback = MockDioClient(
    session,
    actAs: () => MockStore.instance.accountForRole(session.role ?? UserRole.worker),
  );

  /// Builds the live client over [session].
  BackendDioClient(super.session);

  /// Page size of the calendar's month request (the backend maximum).
  static const _calendarPage = 100;

  @override
  Future<Response<dynamic>> request(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final body = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final query = queryParameters ?? const <String, dynamic>{};
    final seg = path.split('/');
    final Object? result;
    switch (seg.first) {
      case 'auth':
        result = switch (seg.length > 1 ? seg[1] : '') {
          'logout' => await _logout(),
          'refresh' => await _refresh(body),
          _ => await _login(body),
        };
      case 'account':
        result = seg.length == 1 ? await _updateAccount(body) : await _changePassword(body);
      case 'tasks':
        result = await _tasks(method, seg, body, query);
      case 'users':
        result = await _users(method, seg, body, query);
      case 'notifications':
        result = await _notifications(method, seg, body, query);
      case 'dashboard':
        result = BackendMapper.dashboard(await _raw('reports/dashboard/'));
      case 'reports' when seg.length > 1 && seg[1] == 'stats':
        result = BackendMapper.stats(await _raw('reports/stats/', query: query));
      case 'reports' when seg.length > 1 && seg[1] == 'export':
        await _raw('reports/export/', method: 'POST', data: body);
        result = const <String, dynamic>{};
      case 'conversations' || 'app-version' || 'support' || 'legal' || 'files' || 'calls':
        return super.request(path, method: method, data: data, queryParameters: queryParameters);
      default:
        return _fallback.request(path, method: method, data: data, queryParameters: queryParameters);
    }
    return Response<dynamic>(
      data: result,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }

  /// Calls the backend itself and returns the decoded body.
  Future<dynamic> _raw(String path, {String method = 'GET', Object? data, Map<String, dynamic>? query}) async =>
      (await super.request(path, method: method, data: data, queryParameters: query)).data;

  // ─── auth ──────────────────────────────────────────────────────────────────

  /// `auth/refresh` → backend `auth/refresh/`; answers the new `{token, refresh}` pair.
  Future<Object?> _refresh(Map<String, dynamic> body) async {
    final data = await _raw('auth/refresh/', method: 'POST', data: {'refresh': body['refresh']}) as Map;
    return {'token': data['token'], 'refresh': data['refresh']};
  }

  /// `auth/logout` → backend `auth/logout/`; returns null (204).
  Future<Object?> _logout() async {
    try {
      await _raw('auth/logout/', method: 'POST');
    } catch (_) {
      // Ignore network errors — the local session is cleared regardless.
    }
    return null;
  }

  /// `auth/login` → backend `auth/login/`.
  Future<Object?> _login(Map<String, dynamic> body) async {
    final data = await _raw(
      'auth/login/',
      method: 'POST',
      data: {'username': body['login'], 'password': body['password']},
    );
    return BackendMapper.session(data);
  }

  /// `PATCH account` → backend `PATCH users/{me}/` with `full_name` and `username`.
  Future<Object?> _updateAccount(Map<String, dynamic> body) async {
    final me = session.user.value!.user.id;
    final data = await _raw(
      'users/$me/',
      method: 'PATCH',
      data: {if (body['name'] != null) 'full_name': body['name'], if (body['login'] != null) 'username': body['login']},
    );
    return BackendMapper.user(data);
  }

  /// `POST account/password` → backend `POST auth/password/`; the backend answers with a fresh token pair.
  Future<Object?> _changePassword(Map<String, dynamic> body) async {
    final data = await _raw(
      'auth/password/',
      method: 'POST',
      data: {'old_password': body['oldPassword'], 'new_password': body['newPassword']},
    );
    return {'token': '${(data as Map)['token']}', 'refresh': '${data['refresh']}'};
  }

  // ─── tasks ─────────────────────────────────────────────────────────────────

  /// Routes the `tasks/...` family.
  Future<Object?> _tasks(String method, List<String> seg, Map<String, dynamic> body, Map<String, dynamic> query) async {
    if (seg.length == 1) return method == 'POST' ? _createTask(body) : _taskList(query);
    if (seg[1] == 'calendar') return _calendar(query);
    final id = seg[1];
    if (seg.length == 2 && method == 'DELETE') {
      await _raw('tasks/$id/', method: 'DELETE');
      return const <String, dynamic>{};
    }
    if (seg.length == 4 && seg[2] == 'comments' && method == 'DELETE') {
      // The app addresses a note by its position; the backend by its id.
      final rows = await _raw('tasks/$id/comments/') as List;
      await _raw('tasks/$id/comments/${(rows[int.parse(seg[3])] as Map)['id']}/', method: 'DELETE');
      return _taskDetail(id);
    }
    if (seg.length == 2) return method == 'PUT' ? _editTask(id, body) : _taskDetail(id);
    if (seg.length > 3 || seg[2] == 'expenses' || seg[2] == 'pay') throw _unsupported();
    switch (seg[2]) {
      case 'cancel':
        await _move(id, 'CANCELED');
      case 'fail':
        await _move(id, 'FAILED', reason: '${body['reason'] ?? ''}');
      case 'progress':
        await _progress(id, body);
      case 'comments':
        await _raw('tasks/$id/comments/', method: 'POST', data: {'body': body['text']});
      case 'submit':
        await _submit(id, '${body['text'] ?? ''}');
      case 'approve':
        // A task nobody started (the admin's own) goes through "in progress" first: the machine has no OPEN → DONE.
        final current = await _raw('tasks/$id/') as Map;
        if (current['status'] == 'OPEN') await _move(id, 'IN_PROGRESS');
        await _move(id, 'COMPLETED');
      case 'return':
        await _move(id, 'IN_PROGRESS', reason: '${body['reason'] ?? ''}');
      default:
        throw _unsupported();
    }
    return _taskDetail(id);
  }

  /// Failure for actions the backend has no endpoint for yet.
  ScreenResponse _unsupported() => const MessageErrorResponse('Bu amal serverda hali mavjud emas.', statusCode: 501);

  /// Query parameters of `GET tasks/` for the app's list query.
  Map<String, dynamic> _taskParams(Map<String, dynamic> q) {
    final today = DateTime.now();
    final params = <String, dynamic>{'page': q['page'] ?? 1, 'page_size': q['pageSize'] ?? 20};
    String? status;
    if ('${q['status'] ?? ''}'.isNotEmpty) {
      status = '${q['status']}'.split(',').map(BackendMapper.backendStatus).join(',');
    } else if (q['group'] == 'active') {
      status = BackendMapper.activeStatuses;
    } else if (q['group'] == 'history') {
      status = BackendMapper.closedStatuses;
    }
    if (q['late'] == '1') {
      status ??= 'OPEN,IN_PROGRESS';
      params['due_before'] = BackendMapper.date(today.subtract(const Duration(days: 1)));
    }
    if (status != null) params['status'] = status;
    if ('${q['q'] ?? ''}'.isNotEmpty) params['q'] = q['q'];
    // The backend filters by one worker; several picked assignees narrow to the first.
    if (q['who'] != null) params['worker'] = '${q['who']}'.split(',').first;
    if (q['from'] != null) params['due_after'] = q['from'];
    if (q['to'] != null) params['due_before'] = q['to'];
    switch (q['due']) {
      case 'today':
        params['due_after'] = params['due_before'] = BackendMapper.date(today);
      case 'week':
        params['due_after'] = BackendMapper.date(today);
        params['due_before'] = BackendMapper.date(today.add(const Duration(days: 6)));
    }
    params['ordering'] = switch (q['sort']) {
      'priority' => '-priority',
      'created' => '-created_at',
      _ => 'due_date',
    };
    return params;
  }

  /// `GET tasks` → paged app task list.
  Future<Object?> _taskList(Map<String, dynamic> q) async {
    final params = _taskParams(q);
    final data = await _raw('tasks/', query: params);
    return BackendMapper.page(
      data,
      page: params['page'] as int,
      pageSize: params['page_size'] as int,
      item: BackendMapper.task,
    );
  }

  /// `GET tasks/{id}` → task with its log and comments (three backend calls).
  Future<Map<String, dynamic>> _taskDetail(String id) async {
    final parts = await Future.wait([_raw('tasks/$id/'), _raw('tasks/$id/history/'), _raw('tasks/$id/comments/')]);
    return BackendMapper.task(parts[0], history: parts[1] as List, comments: parts[2] as List);
  }

  /// `GET tasks/calendar?month=YYYY-M` → every task due in that month.
  Future<Object?> _calendar(Map<String, dynamic> q) async {
    final parts = '${q['month']}'.split('-').map(int.parse).toList();
    final params = <String, dynamic>{
      'due_after': BackendMapper.date(DateTime(parts[0], parts[1])),
      'due_before': BackendMapper.date(DateTime(parts[0], parts[1] + 1, 0)),
      'page_size': _calendarPage,
      'ordering': 'due_date',
    };
    final out = <Object?>[];
    for (var page = 1; ; page++) {
      final data = await _raw('tasks/', query: {...params, 'page': page}) as Map;
      out.addAll([for (final row in data['results'] as List) BackendMapper.task(row)]);
      if (data['next'] == null) return out;
    }
  }

  /// Body of `POST tasks/` / `PATCH tasks/{id}/` for an app `TaskDraft`.
  Map<String, dynamic> _taskBody(Map<String, dynamic> draft) {
    final expected = '${draft['expected'] ?? ''}'.trim();
    final description = '${draft['description'] ?? ''}'.trim();
    final reward = (draft['reward'] as num?)?.toInt() ?? 0;
    final isClient = session.role == UserRole.client;
    return {
      'title': draft['title'],
      'description': expected.isEmpty ? description : '$description\n\n$expected'.trim(),
      // A client may only fill the fields of an order (never priority or client details).
      if (!isClient) 'priority': '${draft['priority']}'.toUpperCase(),
      'due_date': BackendMapper.date(DateTime.parse('${draft['due']}')),
      // The owner prices a task and a client gives the budget of their own order; sending the field as an assistant
      // would be a 403.
      if (reward > 0 && (session.role == UserRole.owner || isClient)) ...{
        'agreed_value': reward,
        'currency': '${draft['currency'] ?? 'uzs'}'.toUpperCase(),
      },
      if (!isClient && '${draft['client'] ?? ''}'.isNotEmpty) 'client_name': draft['client'],
      if (!isClient) 'client_is_org': draft['clientIsOrg'] ?? false,
      'attachment_ids': draft['attachmentIds'] ?? const <int>[],
      'address': draft['address'] ?? '',
    };
  }

  /// Ids of the draft's assignees as the backend's integers.
  List<int> _workerIds(Map<String, dynamic> draft) => [
    for (final a in (draft['assignees'] as List? ?? const [])) int.parse('${((a as Map)['user'] as Map)['id']}'),
  ];

  /// `POST tasks` → creates the task, then returns its detail.
  Future<Object?> _createTask(Map<String, dynamic> draft) async {
    final created = await _raw('tasks/', method: 'POST', data: {..._taskBody(draft), 'worker_ids': _workerIds(draft)});
    return _taskDetail('${(created as Map)['id']}');
  }

  /// `PUT tasks/{id}` → patches the fields, replaces the assignees, returns the detail.
  Future<Object?> _editTask(String id, Map<String, dynamic> draft) async {
    await _raw('tasks/$id/', method: 'PATCH', data: _taskBody(draft));
    if (session.role != UserRole.client) {
      await _raw('tasks/$id/assignees/', method: 'PUT', data: {'worker_ids': _workerIds(draft)});
    }
    return _taskDetail(id);
  }

  /// Moves task [id] to the backend status [to].
  Future<void> _move(String id, String to, {String reason = ''}) =>
      _raw('tasks/$id/transition/', method: 'POST', data: {'to_status': to, if (reason.isNotEmpty) 'reason': reason});

  /// Worker progress: the first report starts the task, "cannot be done" fails it, a note becomes a comment.
  Future<void> _progress(String id, Map<String, dynamic> body) async {
    final note = '${body['note'] ?? ''}'.trim();
    if (body['cant'] == true) {
      await _move(id, 'FAILED', reason: note.isEmpty ? 'Bajarib bo‘lmaydi' : note);
      return;
    }
    if (note.isNotEmpty) await _raw('tasks/$id/comments/', method: 'POST', data: {'body': note});
    final current = await _raw('tasks/$id/') as Map;
    if (current['status'] == 'OPEN') await _move(id, 'IN_PROGRESS');
  }

  /// Result submission: starts the task if needed, then moves it to review with the text as the reason.
  Future<void> _submit(String id, String text) async {
    final current = await _raw('tasks/$id/') as Map;
    if (current['status'] == 'OPEN') await _move(id, 'IN_PROGRESS');
    await _move(id, 'REVIEW', reason: text);
  }

  // ─── users ─────────────────────────────────────────────────────────────────

  /// Routes the `users/...` family.
  Future<Object?> _users(String method, List<String> seg, Map<String, dynamic> body, Map<String, dynamic> q) async {
    if (seg.length == 1) {
      if (method == 'POST') {
        final created = await _raw(
          'users/',
          method: 'POST',
          data: {
            'username': body['id'],
            'full_name': body['name'],
            'phone': body['phone'],
            'role': '${body['role']}'.toUpperCase(),
            'password': body['password'],
            if ('${body['role']}' == 'client') ...{
              'address': body['team'] ?? '',
              'is_org': body['isOrg'] ?? false,
              'contact_person': body['contactPerson'] ?? '',
              'note': body['note'] ?? '',
            },
          },
        );
        return BackendMapper.user(created);
      }
      final page = q['page'] as int? ?? 1;
      final size = q['pageSize'] as int? ?? 30;
      final data = await _raw(
        'users/',
        query: {
          'role': q['role'] == 'client' ? 'CLIENT' : 'OWNER,ASSISTANT,WORKER',
          if ('${q['q'] ?? ''}'.isNotEmpty) 'q': q['q'],
          'page': page,
          'page_size': size,
        },
      );
      return BackendMapper.page(data, page: page, pageSize: size, item: BackendMapper.user);
    }
    final id = seg[1];
    if (seg.length == 2 && method == 'DELETE') return _raw('users/$id/', method: 'DELETE');
    if (seg.length == 2 && method == 'PATCH') {
      return BackendMapper.user(
        await _raw(
          'users/$id/',
          method: 'PATCH',
          data: {
            if (body.containsKey('name')) 'full_name': body['name'],
            if (body.containsKey('phone')) 'phone': body['phone'],
            if (body.containsKey('team')) 'address': body['team'],
            if (body.containsKey('isOrg')) 'is_org': body['isOrg'],
            if (body.containsKey('contactPerson')) 'contact_person': body['contactPerson'],
            if (body.containsKey('note')) 'note': body['note'],
          },
        ),
      );
    }
    if (seg.length == 2) return BackendMapper.user(await _raw('users/$id/'));
    // `users/{id}/permissions`: the backend has roles only, no per-switch flags.
    if (method == 'PUT') {
      await _raw('users/$id/', method: 'PATCH', data: {'role': '${body['role']}'.toUpperCase()});
    }
    final user = await _raw('users/$id/') as Map;
    return {'userId': '$id', 'role': '${user['role']}'.toLowerCase(), 'flags': const <String, bool>{}};
  }

  // ─── notifications ─────────────────────────────────────────────────────────

  /// Routes the `notifications/...` family.
  Future<Object?> _notifications(
    String method,
    List<String> seg,
    Map<String, dynamic> body,
    Map<String, dynamic> q,
  ) async {
    if (seg.length > 1 && seg[1] == 'devices') {
      await _raw('notifications/devices/', method: method, data: body);
      return const <String, dynamic>{};
    }
    if (method == 'POST') {
      final id = int.tryParse('${body['id']}');
      await _raw(
        'notifications/read/',
        method: 'POST',
        data: {
          if (id != null) 'ids': [id],
        },
      );
      return const <String, dynamic>{};
    }
    final page = q['page'] as int? ?? 1;
    final size = q['pageSize'] as int? ?? 20;
    final results = await Future.wait([
      _raw('notifications/', query: {'page': page, 'page_size': size, if (q['group'] == 'unread') 'unread': 'true'}),
      _raw('notifications/unread-count/'),
    ]);
    final me = session.user.value?.user.id ?? '';
    return {
      ...BackendMapper.page(
        results[0],
        page: page,
        pageSize: size,
        item: (n) => BackendMapper.notification(n, userId: me),
      ),
      'unread': (results[1] as Map)['unread'],
    };
  }
}
