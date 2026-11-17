import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/comment_model.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives the notes screen of an own task: loads the task's notes cache-first, adds a note and removes one.
class TaskNotesBloc extends Bloc<TaskNotesEvent, TaskNotesState> {
  /// Data source of every task request; owned by the app root.
  final TasksRepository repository;

  /// Id of the task the notes belong to.
  final String taskId;

  /// Wires the handlers of the screen.
  TaskNotesBloc({required this.repository, required this.taskId}) : super(const TaskNotesState()) {
    on<TaskNotesStarted>(_load);
    on<TaskNotesAdded>((event, emit) => _act(emit, () => repository.addComment(taskId, event.text)));
    on<TaskNotesRemoved>((event, emit) => _act(emit, () => repository.deleteComment(taskId, event.index)));
  }

  /// Emits the cached notes first (if any), then the fresh ones; an error keeps cached notes on screen.
  Future<void> _load(TaskNotesStarted event, Emitter<TaskNotesState> emit) async {
    /// Notes remembered with the cached task; empty when it was never opened.
    final cached = repository.cachedTask(taskId)?.comments ?? const <CommentModel>[];
    emit(
      state.copyWith(
        notes: cached,
        refreshing: true,
        status: cached.isEmpty ? ScreenStatus.loading : ScreenStatus.success,
      ),
    );
    try {
      emit(
        state.copyWith(
          notes: (await repository.getTask(taskId)).comments,
          status: ScreenStatus.success,
          refreshing: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: state.notes.isEmpty ? ScreenStatus.error : ScreenStatus.success,
          refreshing: false,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
        ),
      );
    }
  }

  /// Runs one mutation and replaces the notes with the task the server answers.
  Future<void> _act(Emitter<TaskNotesState> emit, Future<TaskModel> Function() action) async {
    emit(state.copyWith(busy: true));
    try {
      emit(state.copyWith(notes: (await action()).comments, busy: false));
    } catch (e) {
      emit(state.copyWith(busy: false, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
      // A swiped-away note is already off screen: reload so a failed delete brings it back.
      add(const TaskNotesStarted());
    }
  }
}
