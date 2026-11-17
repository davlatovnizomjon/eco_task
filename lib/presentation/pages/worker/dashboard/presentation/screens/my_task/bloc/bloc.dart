import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives the worker's task screen: loads the task cache-first, hands the result in, reports it as not done, or
/// opens the chat with the manager who gave it.
class MyTaskBloc extends Bloc<MyTaskEvent, MyTaskState> {
  /// Data source of every task request; owned by the app root.
  final TasksRepository repository;

  /// Opens the direct chat with the person who gave the task.
  final ChatRepository chats;

  /// Id of the task this screen shows.
  final String taskId;

  /// Wires the handlers of the screen.
  MyTaskBloc({required this.repository, required this.chats, required this.taskId}) : super(const MyTaskState()) {
    on<MyTaskStarted>((event, emit) => _load(emit, refreshing: false));
    on<MyTaskRefreshed>((event, emit) => _load(emit, refreshing: true));
    // A worker hands the result to the manager (review); only the manager marks a task done for good.
    on<MyTaskCompleted>((event, emit) => _act(emit, () => repository.submitResult(taskId, '')));
    on<MyTaskFailed>((event, emit) => _act(emit, () => repository.failTask(taskId, event.reason)));
    on<MyTaskChatOpened>(_onChat);
  }

  /// Opens (or finds) the direct chat with the task's creator and asks the screen to show it.
  Future<void> _onChat(MyTaskChatOpened event, Emitter<MyTaskState> emit) async {
    final creator = state.task?.createdBy;
    if (creator == null) return;
    try {
      emit(state.copyWith(chatId: (await chats.openDirect(creator.id)).id));
    } catch (e) {
      emit(state.copyWith(response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }

  /// Emits the cached task first (if any), then the fresh one. An error keeps a cached task on screen and only
  /// surfaces the failure.
  Future<void> _load(Emitter<MyTaskState> emit, {required bool refreshing}) async {
    /// Task remembered from an earlier visit; null on the first one.
    final cached = repository.cachedTask(taskId);
    emit(
      state.copyWith(
        task: cached,
        refreshing: refreshing,
        status: cached == null ? ScreenStatus.loading : ScreenStatus.success,
      ),
    );
    try {
      emit(state.copyWith(task: await repository.getTask(taskId), status: ScreenStatus.success, refreshing: false));
    } catch (e) {
      emit(
        state.copyWith(
          status: state.task == null ? ScreenStatus.error : ScreenStatus.success,
          refreshing: false,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
        ),
      );
    }
  }

  /// Runs one closing action; on success asks the screen to pop, on failure surfaces the error.
  Future<void> _act(Emitter<MyTaskState> emit, Future<Object?> Function() action) async {
    emit(state.copyWith(busy: true));
    try {
      await action();
      emit(state.copyWith(busy: false, closeScreen: true));
    } catch (e) {
      emit(state.copyWith(busy: false, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }
}
