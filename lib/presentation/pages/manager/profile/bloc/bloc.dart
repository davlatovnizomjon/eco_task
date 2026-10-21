import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/reports_repository.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/infrastructure/dto/models/profile_summary.dart';

part 'event.dart';
part 'state.dart';

/// Drives the profile tab: loads the role's summary numbers (cache first) and
/// performs sign-out through the app-wide [SessionRepository].
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  /// Data source of the summary numbers; owned by the app root.
  final ReportsRepository reports;

  /// App-wide session; sign-out clears it and the router reacts.
  final SessionRepository session;

  /// Wires the handlers of the profile.
  ProfileBloc({required this.reports, required this.session}) : super(const ProfileState()) {
    on<ProfileStarted>((event, emit) => _load(emit, refreshing: false));
    on<ProfileRefreshed>((event, emit) => _load(emit, refreshing: true));
    on<ProfileSignedOut>((event, emit) => session.clearSession());
  }

  /// Emits the cached summary first (if any), then the fresh one. An error
  /// keeps a cached summary on screen and only surfaces the failure.
  Future<void> _load(Emitter<ProfileState> emit, {required bool refreshing}) async {
    final cached = reports.cachedProfile();
    emit(
      state.copyWith(
        summary: cached,
        refreshing: refreshing,
        status: cached == null ? ScreenStatus.loading : ScreenStatus.success,
      ),
    );
    try {
      emit(state.copyWith(summary: await reports.getProfile(), status: ScreenStatus.success, refreshing: false));
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
