import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';

part 'event.dart';
part 'state.dart';

/// Drives the calendar: the visible month, the selected day and the tasks
/// whose deadline falls into the month, served cache-first.
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  /// Data source of the month's tasks; owned by the app root.
  final TasksRepository repository;

  /// Wires the handlers of the calendar.
  CalendarBloc({required this.repository}) : super(CalendarState(month: DateTime.now(), selected: DateTime.now())) {
    on<CalendarStarted>((event, emit) => _load(emit, refreshing: false));
    on<CalendarRefreshed>((event, emit) => _load(emit, refreshing: true));
    on<CalendarMonthChanged>((event, emit) {
      emit(state.copyWith(month: event.month));
      return _load(emit, refreshing: false);
    });
    on<CalendarDaySelected>((event, emit) => emit(state.copyWith(selected: event.day)));
  }

  /// Emits the cached month first (if any), then the fresh one. An error keeps
  /// the cached tasks on screen; a response for a month that is no longer
  /// visible is dropped.
  Future<void> _load(Emitter<CalendarState> emit, {required bool refreshing}) async {
    final month = state.month;
    final cached = repository.cachedCalendar(month);
    emit(
      state.copyWith(
        tasks: cached,
        refreshing: refreshing,
        status: cached.isEmpty ? ScreenStatus.loading : ScreenStatus.success,
      ),
    );
    try {
      final fresh = await repository.getCalendar(month);
      if (state.month.year != month.year || state.month.month != month.month) return;
      emit(state.copyWith(tasks: fresh, status: ScreenStatus.success, refreshing: false));
    } catch (e) {
      if (state.month.year != month.year || state.month.month != month.month) return;
      emit(
        state.copyWith(
          status: state.tasks.isEmpty ? ScreenStatus.error : ScreenStatus.success,
          refreshing: false,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
        ),
      );
    }
  }
}
