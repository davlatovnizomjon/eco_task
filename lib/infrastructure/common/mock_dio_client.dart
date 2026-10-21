import 'package:dio/dio.dart';

import 'package:eco_task/infrastructure/dto/models/app_user.dart';

import 'api_links.dart';
import 'dio_client.dart';
import 'mock_json_data/mock_chat.dart';
import 'mock_json_data/mock_store.dart';

/// Offline stand-in for [DioClient]. It answers from the in-memory
/// `MockStore` instead of the network.
///
/// Because it only overrides [request], every repository, bloc and screen
/// above it is byte-for-byte the code that will run against the real API —
/// switching back is the one-line change in `AppConfig.useMockData`.
class MockDioClient extends DioClient {
  /// Wraps the same session the real client uses. [actAs], when given, names
  /// the mock account every request is served for (used by `BackendDioClient`,
  /// whose live token means nothing to the mock store).
  MockDioClient(super.session, {this.actAs});

  /// Resolves the mock account to act as; null means "look the token up".
  final AppUser? Function()? actAs;

  /// Round-trip latency the mock simulates, so shimmer loading is visible.
  static const _latency = Duration(milliseconds: 600);

  /// The in-memory backend every request is routed to.
  MockStore get _store => MockStore.instance;

  @override
  Future<Response<dynamic>> request(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    await Future<void>.delayed(_latency);
    // Bodies arrive as plain maps; anything else (a null body) is empty.
    final body = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    try {
      return Response<dynamic>(
        data: _route(method, path, body, queryParameters ?? const {}),
        statusCode: 200,
        requestOptions: RequestOptions(path: path),
      );
    } on MockFailure catch (failure) {
      await _failure(path, failure.status, failure.detail);
    }
  }

  /// Dispatches `method path` to the store, as the live router would.
  /// Throws [MockFailure] for scripted 4xx answers.
  Object? _route(String method, String path, Map<String, dynamic> body, Map<String, dynamic> query) {
    if (path == ApiLinks.authLogin) return _store.login('${body['login']}', '${body['password']}');
    final me = actAs?.call() ?? _store.userForToken(session.token);
    if (me == null) throw const MockFailure(401, 'Seans tugagan. Qayta kiring.');
    final seg = path.split('/');
    final post = method == 'POST';
    switch (seg.first) {
      case 'tasks':
        return _tasks(me, method, seg, body, query);
      case 'expenses':
        return seg.length == 1 ? _store.expenses(me, query) : _store.expensesSummary(me);
      case 'users':
        return _users(me, method, seg, body, query);
      case 'notifications':
        if (!post) return _store.notifications(me, query);
        _store.markRead(me, body);
        return const <String, dynamic>{};
      case 'dashboard':
        return _store.dashboard(me);
      case 'reports':
        return _store.reports(me, query);
      case 'profile':
        return _store.profileSummary(me);
      case 'conversations':
        return MockChat.instance.route(me, method, seg, body, query);
    }
    throw MockFailure(404, 'Mock uchun bu endpoint yozilmagan: $path');
  }

  /// Routes the `tasks/...` family.
  Object? _tasks(AppUser me, String method, List<String> seg, Map<String, dynamic> body, Map<String, dynamic> query) {
    if (seg.length == 1) return method == 'POST' ? _store.createTask(me, body) : _store.tasksPage(me, query);
    if (seg[1] == 'calendar') return _store.calendar(me, query);
    final id = seg[1];
    if (seg.length == 2) return method == 'PUT' ? _store.editTask(id, body) : _store.task(id);
    if (seg.length == 5) {
      return seg[4] == 'review' ? _store.reviewExpense(id, seg[3], body) : _store.payExpense(id, seg[3]);
    }
    return switch (seg[2]) {
      'cancel' => _store.cancelTask(me, id),
      'progress' => _store.progress(me, id, body),
      'comments' => _store.addComment(me, id, body),
      'expenses' => _store.addExpense(me, id, body),
      'submit' => _store.submit(me, id, body),
      'approve' => _store.approve(me, id),
      'return' => _store.returnTask(me, id, body),
      'pay' => _store.payReward(id),
      _ => throw MockFailure(404, 'Mock uchun bu endpoint yozilmagan: ${seg.join('/')}'),
    };
  }

  /// Routes the `users/...` family.
  Object? _users(AppUser me, String method, List<String> seg, Map<String, dynamic> body, Map<String, dynamic> query) {
    if (seg.length == 1) return method == 'POST' ? _store.addUser(body) : _store.usersPage(me, query);
    if (seg.length == 2) return _store.user(seg[1]);
    return method == 'PUT' ? _store.savePermissions(seg[1], body) : _store.permissions(seg[1]);
  }

  /// Builds the same RFC 7807 body the live backend sends and runs it
  /// through [mapError], so the mock throws real typed failures and never
  /// returns to its caller.
  Future<Never> _failure(String path, int status, String detail) async {
    final options = RequestOptions(path: path);
    throw await mapError(
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: status,
          data: {'title': 'Xatolik', 'status': status, 'detail': detail, 'traceId': 'mock-trace'},
        ),
      ),
    );
  }
}
