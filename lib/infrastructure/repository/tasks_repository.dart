import '../common/api_cache.dart';
import '../common/api_links.dart';
import '../dto/models/paged_list.dart';
import '../dto/models/task_draft.dart';
import '../dto/models/task_model.dart';
import '../dto/models/task_query.dart';

import 'package:eco_task/infrastructure/common/dio_client.dart';

/// All task reads and writes: lists, details, calendar and every task action.
/// Provided once at the app root; screens reach it through their blocs.
class TasksRepository {
  /// Rows per page on every task list (fills a tall screen with a little spare).
  static const pageSize = 20;

  /// Cached first page of [query], or an empty page when nothing is cached.
  PagedList<TaskModel> cachedTasks(TaskQuery query) =>
      ApiCache.read<PagedList<TaskModel>>(query.cacheKey) ?? const PagedList();

  /// Loads page [page] of [query]; page 1 refreshes the cache.
  Future<PagedList<TaskModel>> getTasks(TaskQuery query, {int page = 1}) async {
    final response = await dioClient.get(ApiLinks.tasks, queryParameters: query.toParams(page, pageSize));
    final result = PagedList.fromJson(response.data as Map<String, dynamic>, TaskModel.fromJson);
    return page == 1 ? ApiCache.write(query.cacheKey, result) : result;
  }

  /// Cached task [id], or null when it was never opened.
  TaskModel? cachedTask(String id) => ApiCache.read<TaskModel>('task|$id');

  /// Loads task [id] with its expenses, comments and log.
  Future<TaskModel> getTask(String id) async {
    final response = await dioClient.get(ApiLinks.task(id));
    return ApiCache.write('task|$id', TaskModel.fromJson(response.data as Map<String, dynamic>));
  }

  /// Cached tasks of [month], or an empty list.
  List<TaskModel> cachedCalendar(DateTime month) =>
      ApiCache.read<List<TaskModel>>('cal|${month.year}-${month.month}') ?? const [];

  /// Loads every task whose deadline falls into [month].
  Future<List<TaskModel>> getCalendar(DateTime month) async {
    final response = await dioClient.get(ApiLinks.calendar, queryParameters: {'month': '${month.year}-${month.month}'});
    final list = [for (final t in response.data as List) TaskModel.fromJson(t as Map<String, dynamic>)];
    return ApiCache.write('cal|${month.year}-${month.month}', list);
  }

  /// Parses a mutation answer and drops every cached list.
  TaskModel _changed(Object? data) {
    ApiCache.invalidate();
    return TaskModel.fromJson(data as Map<String, dynamic>);
  }

  /// Creates a task from [draft].
  Future<TaskModel> createTask(TaskDraft draft) async =>
      _changed((await dioClient.post(ApiLinks.tasks, data: draft.toJson())).data);

  /// Replaces the editable fields of task [id] with [draft].
  Future<TaskModel> editTask(String id, TaskDraft draft) async =>
      _changed((await dioClient.put(ApiLinks.task(id), data: draft.toJson())).data);

  /// Cancels task [id].
  Future<TaskModel> cancelTask(String id) async => _changed((await dioClient.post(ApiLinks.taskCancel(id))).data);

  /// Removes the comment at position [index] of task [id].
  Future<TaskModel> deleteComment(String id, int index) async =>
      _changed((await dioClient.delete(ApiLinks.taskComment(id, index))).data);

  /// Closes task [id] as failed with the [reason] the performer gives.
  Future<TaskModel> failTask(String id, String reason) async =>
      _changed((await dioClient.post(ApiLinks.taskFail(id), data: {'reason': reason})).data);

  /// Deletes task [id] for good and drops every cached list.
  Future<void> deleteTask(String id) async {
    await dioClient.delete(ApiLinks.task(id));
    ApiCache.invalidate();
  }

  /// Reports the signed-in worker's progress; [cant] marks the task as impossible.
  Future<TaskModel> reportProgress(String id, {required int done, required bool cant, String note = ''}) async =>
      _changed(
        (await dioClient.post(ApiLinks.taskProgress(id), data: {'done': done, 'cant': cant, 'note': note})).data,
      );

  /// Adds a comment to task [id].
  Future<TaskModel> addComment(String id, String text) async =>
      _changed((await dioClient.post(ApiLinks.taskComments(id), data: {'text': text})).data);

  /// Adds an expense to task [id].
  Future<TaskModel> addExpense(
    String id, {
    required int amount,
    required String kind,
    required String note,
    required bool hasReceipt,
  }) async => _changed(
    (await dioClient.post(
      ApiLinks.taskExpenses(id),
      data: {'amount': amount, 'kind': kind, 'note': note, 'hasReceipt': hasReceipt},
    )).data,
  );

  /// Submits the result text of task [id] for review.
  Future<TaskModel> submitResult(String id, String text) async =>
      _changed((await dioClient.post(ApiLinks.taskSubmit(id), data: {'text': text})).data);

  /// Approves the submitted result of task [id].
  Future<TaskModel> approve(String id) async => _changed((await dioClient.post(ApiLinks.taskApprove(id))).data);

  /// Returns task [id] for rework; [extend] pushes the deadline back.
  Future<TaskModel> returnForRework(String id, {required String reason, required bool extend}) async =>
      _changed((await dioClient.post(ApiLinks.taskReturn(id), data: {'reason': reason, 'extend': extend})).data);

  /// Marks the reward of task [id] as paid out.
  Future<TaskModel> payReward(String id) async => _changed((await dioClient.post(ApiLinks.taskPay(id))).data);

  /// Clears the cache (called on sign-out and from tests).
  void dispose() => ApiCache.invalidate();
}
