import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/reports_repository.dart';
import 'package:eco_task/infrastructure/dto/models/dashboard_summary.dart';

part 'event.dart';
part 'state.dart';

/// Drives the boss dashboard: loads the summary numbers cache-first and
/// refreshes them on demand.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  /// Data source of the aggregated numbers; owned by the app root.
  final ReportsRepository repository;

  /// Wires the handlers of the dashboard.
  DashboardBloc({required this.repository}) : super(const DashboardState()) {
    on<DashboardStarted>((event, emit) => _load(emit, refreshing: false));
    on<DashboardRefreshed>((event, emit) => _load(emit, refreshing: true));
  }

  /// Emits the cached summary first (if any), then the fresh one. An error keeps
  /// a cached summary on screen and only surfaces the failure.
  Future<void> _load(Emitter<DashboardState> emit, {required bool refreshing}) async {
    final cached = repository.cachedDashboard();
    emit(
      state.copyWith(
        summary: cached,
        refreshing: refreshing,
        status: cached == null ? ScreenStatus.loading : ScreenStatus.success,
      ),
    );
    try {
      emit(state.copyWith(summary: await repository.getDashboard(), status: ScreenStatus.success, refreshing: false));
    } catch (e) {
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
