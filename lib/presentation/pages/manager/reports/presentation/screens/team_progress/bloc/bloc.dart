import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/reports_repository.dart';
import 'package:eco_task/domain/common/enums/report_period.dart';
import 'package:eco_task/infrastructure/dto/models/report_summary.dart';

part 'event.dart';
part 'state.dart';

/// Drives the team-progress screen: per-person results for the selected period, served cache-first.
class TeamProgressBloc extends Bloc<TeamProgressEvent, TeamProgressState> {
  /// Data source of the aggregated numbers; owned by the app root.
  final ReportsRepository repository;

  /// Wires the handlers of the screen.
  TeamProgressBloc({required this.repository}) : super(const TeamProgressState()) {
    on<TeamProgressStarted>((event, emit) => _load(emit, refreshing: false));
    on<TeamProgressRefreshed>((event, emit) => _load(emit, refreshing: true));
    on<TeamProgressPeriodChanged>((event, emit) {
      emit(state.copyWith(period: event.period));
      return _load(emit, refreshing: false);
    });
  }

  /// Emits the cached report of the selected period first (if any), then the
  /// fresh one. An error keeps a cached report on screen; a response for a
  /// period that is no longer selected is dropped.
  Future<void> _load(Emitter<TeamProgressState> emit, {required bool refreshing}) async {
    final period = state.period;
    final cached = repository.cachedReport(period);
    emit(
      state.copyWith(
        summary: cached,
        refreshing: refreshing,
        status: cached == null ? ScreenStatus.loading : ScreenStatus.success,
      ),
    );
    try {
      final fresh = await repository.getReport(period);
      if (state.period != period) return;
      emit(state.copyWith(summary: fresh, status: ScreenStatus.success, refreshing: false));
    } catch (e) {
      if (state.period != period) return;
      emit(
        state.copyWith(
          status: state.summary == null ? ScreenStatus.error : ScreenStatus.success,
          refreshing: false,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
        ),
      );
    }
  }
}
