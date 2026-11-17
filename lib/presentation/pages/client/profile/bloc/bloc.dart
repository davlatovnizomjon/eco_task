import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/support_contact.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/infrastructure/repository/support_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives the client profile tab: loads the dispatcher contacts for the help sheet (cache first) and signs out.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  /// Source of the dispatcher contacts; owned by the app root.
  final SupportRepository support;

  /// Session to clear on sign-out.
  final SessionRepository session;

  /// Wires the handlers of the profile tab.
  ProfileBloc({required this.support, required this.session}) : super(const ProfileState()) {
    on<ProfileStarted>((event, emit) => _load(emit, refreshing: false));
    on<ProfileRefreshed>((event, emit) => _load(emit, refreshing: true));
    on<ProfileSignedOut>(_onSignedOut);
  }

  /// Emits the cached contacts first (if any), then the fresh ones; an error keeps what is shown.
  Future<void> _load(Emitter<ProfileState> emit, {required bool refreshing}) async {
    emit(state.copyWith(contact: support.cached, refreshing: refreshing));
    try {
      emit(state.copyWith(contact: await support.getContact(), refreshing: false));
    } catch (e) {
      emit(state.copyWith(refreshing: false, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }

  /// Ends the session; the router then moves to the sign-in screen by itself.
  Future<void> _onSignedOut(ProfileSignedOut event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(signingOut: true));
    await session.clearSession();
  }
}
