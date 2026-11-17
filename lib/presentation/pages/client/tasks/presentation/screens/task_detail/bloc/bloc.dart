import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives one task's details screen: loads the task (cache first) and applies
/// every action on it — approve, return for rework, delete.
class TaskDetailBloc extends Bloc<TaskDetailEvent, TaskDetailState> {
  /// Data source of every task request; owned by the app root.
  final TasksRepository repository;

  /// Id of the task this screen shows.
  final String taskId;

  /// Wires the handlers of the details screen.
  TaskDetailBloc({required this.repository, required this.taskId}) : super(const TaskDetailState()) {
    on<TaskDetailStarted>((event, emit) => _load(emit, refreshing: false));
    on<TaskDetailRefreshed>((event, emit) => _load(emit, refreshing: true));
    on<TaskDetailApproved>((event, emit) => _act(emit, () => repository.approve(taskId), close: true));
    on<TaskDetailReturned>(
      (event, emit) => _act(emit, () => repository.returnForRework(taskId, reason: event.reason, extend: event.extend)),
    );
    on<TaskDetailDeleted>(_onDeleted);
  }

  /// Emits the cached task first (if any), then the fresh one. An error keeps
  /// a cached task on screen and only surfaces the failure.
  Future<void> _load(Emitter<TaskDetailState> emit, {required bool refreshing}) async {
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

  /// Deletes the task for good and asks the screen to pop; a failure goes to `response`.
  Future<void> _onDeleted(TaskDetailDeleted event, Emitter<TaskDetailState> emit) async {
    emit(state.copyWith(busy: true));
    try {
      await repository.deleteTask(taskId);
      emit(state.copyWith(busy: false, closeScreen: true));
    } catch (e) {
      emit(state.copyWith(busy: false, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }

  /// Runs one mutation, replaces the task with the answer and, when [close] is
  /// true, asks the screen to pop afterwards. Failures go to `response`.
  Future<void> _act(Emitter<TaskDetailState> emit, Future<TaskModel> Function() action, {bool close = false}) async {
    emit(state.copyWith(busy: true));
    try {
      emit(state.copyWith(task: await action(), busy: false, closeScreen: close));
    } catch (e) {
      emit(state.copyWith(busy: false, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }
}
