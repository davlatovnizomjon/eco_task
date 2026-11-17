import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/stats_kind.dart';
import 'package:eco_task/domain/common/enums/stats_period.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/stats_report.dart';
import 'package:eco_task/infrastructure/repository/reports_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives one statistics screen: loads the numbers of the selected window cache-first, moves between windows and
/// prepares the downloadable report.
class StatsBloc extends Bloc<StatsEvent, StatsState> {
  /// Data source of the statistics; owned by the app root.
  final ReportsRepository repository;

  /// Which of the four screens this bloc serves.
  final StatsKind kind;

  /// Wires the handlers of the screen.
  StatsBloc({required this.repository, required this.kind}) : super(const StatsState()) {
    on<StatsStarted>((event, emit) => _load(emit, state.period, state.offset, refreshing: false));
    on<StatsRefreshed>((event, emit) => _load(emit, state.period, state.offset, refreshing: true));
    on<StatsPeriodChanged>((event, emit) => _load(emit, event.period, 0, refreshing: false));
    on<StatsShifted>((event, emit) {
      /// Window after the step; the future (above 0) does not exist.
      final next = state.offset + event.step;
      if (next > 0) return Future<void>.value();
      return _load(emit, state.period, next, refreshing: false);
    });
    on<StatsExported>(_onExported);
  }

  /// Emits the cached report of the window first (if any), then the fresh one. A response for a window the user
  /// already left is dropped; an error keeps a cached report on screen.
  Future<void> _load(Emitter<StatsState> emit, StatsPeriod period, int offset, {required bool refreshing}) async {
    /// Report remembered for this window; null when it was never loaded.
    final cached = repository.cachedStats(kind, period, offset);
    emit(
      state.copyWith(
        period: period,
        offset: offset,
        report: cached,
        clearReport: cached == null,
        refreshing: refreshing,
        status: cached == null ? ScreenStatus.loading : ScreenStatus.success,
      ),
    );
    try {
      /// Fresh numbers of the window.
      final fresh = await repository.getStats(kind, period, offset);
      if (state.period != period || state.offset != offset) return;
      emit(state.copyWith(report: fresh, status: ScreenStatus.success, refreshing: false));
    } catch (e) {
      if (state.period != period || state.offset != offset) return;
      emit(
        state.copyWith(
          status: state.report == null ? ScreenStatus.error : ScreenStatus.success,
          refreshing: false,
          response: state.report == null ? null : (e is ScreenResponse ? e : const UnExpectedErrorResponse()),
        ),
      );
    }
  }

  /// Prepares the file of the current window; the screen shows a spinner meanwhile and a success note after.
  Future<void> _onExported(StatsExported event, Emitter<StatsState> emit) async {
    if (state.exporting || state.report == null) return;
    emit(state.copyWith(exporting: true));
    try {
      await repository.exportStats(kind, state.period, state.offset);
      emit(state.copyWith(exporting: false, response: MessageSuccessResponse(TrWords.sxExported.tr())));
    } catch (e) {
      emit(state.copyWith(exporting: false, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }
}
