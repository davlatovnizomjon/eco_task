import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';

part 'event.dart';
part 'state.dart';

/// Drives the "submit result" screen of one task: loads the task for the
/// checklist, keeps the summary text and photo count, validates that at least
/// one photo is attached and sends the result for review.
class ResultSubmitBloc extends Bloc<ResultSubmitEvent, ResultSubmitState> {
  /// Data source of task reads and writes; owned by the app root.
  final TasksRepository repository;

  /// Id of the task being submitted.
  final String taskId;

  /// Wires the handlers of the screen.
  ResultSubmitBloc({required this.repository, required this.taskId}) : super(const ResultSubmitState()) {
    on<ResultSubmitStarted>(_onStarted);
    on<ResultSubmitTextChanged>((event, emit) => emit(state.copyWith(text: event.value)));
    on<ResultSubmitPhotoAdded>((event, emit) => emit(state.copyWith(photos: state.photos + 1)));
    on<ResultSubmitSent>(_onSent);
  }

  /// Loads the task, cache first, so the checklist reflects real progress.
  Future<void> _onStarted(ResultSubmitStarted event, Emitter<ResultSubmitState> emit) async {
    emit(state.copyWith(task: repository.cachedTask(taskId), status: ScreenStatus.loading));
    try {
      emit(state.copyWith(task: await repository.getTask(taskId), status: ScreenStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: state.task == null ? ScreenStatus.error : ScreenStatus.success,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
        ),
      );
    }
  }

  /// Validates the photo requirement, then submits. A failed validation emits
  /// the message and flips `showErrors`; nothing is sent.
  Future<void> _onSent(ResultSubmitSent event, Emitter<ResultSubmitState> emit) async {
    final invalid = state.photoError;
    if (invalid != null) {
      emit(state.copyWith(showErrors: true, response: MessageErrorResponse(invalid)));
      return;
    }
    emit(state.copyWith(status: ScreenStatus.loading, showErrors: true));
    try {
      await repository.submitResult(taskId, state.text.trim());
      emit(state.copyWith(status: ScreenStatus.success, saved: true));
    } catch (e) {
      emit(
        state.copyWith(
          status: ScreenStatus.success,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
        ),
      );
    }
  }
}
