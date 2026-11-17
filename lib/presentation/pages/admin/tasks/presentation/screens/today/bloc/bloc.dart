import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/infrastructure/repository/reports_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives the "today's tasks" list: the dashboard's due-today set, cache first, with a quick status filter.
class TodayBloc extends Bloc<TodayEvent, TodayState> {
  /// Source of the due-today set; owned by the app root.
  final ReportsRepository repository;

  /// Wires the handlers of the list.
  TodayBloc({required this.repository}) : super(const TodayState()) {
    on<TodayStarted>((event, emit) => _load(emit, refreshing: false));
    on<TodayRefreshed>((event, emit) => _load(emit, refreshing: true));
    on<TodayFilterChanged>((event, emit) => emit(state.copyWith(filter: event.filter)));
  }

  /// Emits the cached set first (if any), then the fresh one. An error keeps a cached list on screen.
  Future<void> _load(Emitter<TodayState> emit, {required bool refreshing}) async {
    final cached = repository.cachedDashboard()?.dueToday;
    emit(
      state.copyWith(
        tasks: cached,
        refreshing: refreshing,
        status: cached == null ? ScreenStatus.loading : ScreenStatus.success,
      ),
    );
    try {
      final fresh = await repository.getDashboard();
      emit(state.copyWith(tasks: fresh.dueToday, status: ScreenStatus.success, refreshing: false));
    } catch (e) {
      emit(
        state.copyWith(
          status: state.tasks.isEmpty && cached == null ? ScreenStatus.error : ScreenStatus.success,
          refreshing: false,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
        ),
      );
    }
  }
}
