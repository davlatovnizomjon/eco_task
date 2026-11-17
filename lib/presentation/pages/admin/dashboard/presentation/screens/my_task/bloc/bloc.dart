import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives the admin's own task screen: loads the task cache-first and closes it as done, failed or deleted.
class MyTaskBloc extends Bloc<MyTaskEvent, MyTaskState> {
  /// Data source of every task request; owned by the app root.
  final TasksRepository repository;

  /// Id of the task this screen shows.
  final String taskId;

  /// Wires the handlers of the screen.
  MyTaskBloc({required this.repository, required this.taskId}) : super(const MyTaskState()) {
    on<MyTaskStarted>((event, emit) => _load(emit, refreshing: false));
    on<MyTaskRefreshed>((event, emit) => _load(emit, refreshing: true));
    on<MyTaskCompleted>((event, emit) => _act(emit, () => repository.approve(taskId)));
    on<MyTaskFailed>((event, emit) => _act(emit, () => repository.failTask(taskId, event.reason)));
    on<MyTaskDeleted>((event, emit) => _act(emit, () => repository.deleteTask(taskId)));
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
