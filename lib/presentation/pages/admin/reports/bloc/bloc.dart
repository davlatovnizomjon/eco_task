import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/reports_repository.dart';
import 'package:eco_task/domain/common/enums/report_period.dart';
import 'package:eco_task/infrastructure/dto/models/report_summary.dart';

part 'event.dart';
part 'state.dart';

/// Drives the reports tab: loads the aggregated report of the selected period cache-first.
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  /// Data source of the aggregated numbers; owned by the app root.
  final ReportsRepository repository;

  /// Wires the handlers of the screen.
  ReportsBloc({required this.repository}) : super(const ReportsState()) {
    on<ReportsStarted>((event, emit) => _load(emit, refreshing: false));
    on<ReportsRefreshed>((event, emit) => _load(emit, refreshing: true));
    on<ReportsPeriodChanged>((event, emit) {
      emit(state.copyWith(period: event.period));
      return _load(emit, refreshing: false);
    });
  }

  /// Emits the cached report of the selected period first (if any), then the
  /// fresh one. An error keeps a cached report on screen; a response for a
  /// period that is no longer selected is dropped.
  Future<void> _load(Emitter<ReportsState> emit, {required bool refreshing}) async {
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
