import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/login_lock_repository.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives the sign-in screen: validates the fields, signs in, counts wrong attempts and locks the account for 5 minutes
/// after the last one, ticking the countdown every second. The end of the lock is remembered on the device, so a lock
/// that has not run out is still there (with the time that is left) when the app is closed and opened again.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Owner of the session; owned by the app root.
  final SessionRepository repository;

  /// Remembers the end of the lock across app restarts; owned by the app root.
  final LoginLockRepository lockRepository;

  /// Ticks while the account is locked; null otherwise.
  Timer? _ticker;

  /// Wires the handlers of the screen and resumes a lock saved by an earlier run.
  AuthBloc({required this.repository, required this.lockRepository}) : super(_initial(lockRepository)) {
    on<AuthLoginChanged>((event, emit) => emit(state.copyWith(login: event.login, credentialsWrong: false)));
    on<AuthPasswordChanged>((event, emit) => emit(state.copyWith(password: event.password, credentialsWrong: false)));
    on<AuthSubmitted>(_onSubmitted);
    on<AuthTicked>(_onTicked);
    if (state.locked) _startTicker();
  }

  /// First state: locked with the saved time left when a lock from an earlier run is still running.
  static AuthState _initial(LoginLockRepository lock) {
    final until = lock.lockedUntil;
    if (until == null) return const AuthState();
    return AuthState(lockedUntil: until, remaining: until.difference(DateTime.now()), attemptsLeft: 0);
  }

  /// Signs in. A locked account is ignored (the screen shows the lock banner and a disabled button) and an empty field
  /// is answered with an amber toast, both without a request; a 401 (or 429) counts as a wrong attempt, and the last
  /// allowed one locks the account.
  Future<void> _onSubmitted(AuthSubmitted event, Emitter<AuthState> emit) async {
    if (state.locked) return;
    if (state.loginEmpty || state.passwordEmpty) {
      emit(state.copyWith(showErrors: true, toast: AuthToast.empty, toastSeq: state.toastSeq + 1));
      return;
    }
    emit(state.copyWith(status: ScreenStatus.loading, showErrors: true, toast: AuthToast.none));
    try {
      await repository.login(login: state.login.trim(), password: state.password);
      emit(state.copyWith(status: ScreenStatus.success));
    } catch (e) {
      final code = e is MessageErrorResponse ? e.statusCode : null;
      if (code == 429) {
        _lock(emit);
      } else if (code == 401) {
        final left = (state.attemptsLeft - 1).clamp(0, AuthState.maxAttempts);
        if (left == 0) {
          _lock(emit);
        } else {
          emit(
            state.copyWith(
              status: ScreenStatus.initial,
              credentialsWrong: true,
              attemptsLeft: left,
              toast: AuthToast.wrong,
              toastSeq: state.toastSeq + 1,
            ),
          );
        }
      } else {
        emit(
          state.copyWith(
            status: ScreenStatus.initial,
            toast: AuthToast.none,
            response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
          ),
        );
      }
    }
  }

  /// Locks the account for [AuthState.lockDuration] and starts the countdown.
  void _lock(Emitter<AuthState> emit) {
    final until = DateTime.now().add(AuthState.lockDuration);
    lockRepository.save(until);
    emit(
      state.copyWith(
        status: ScreenStatus.initial,
        credentialsWrong: false,
        attemptsLeft: 0,
        lockedUntil: until,
        remaining: AuthState.lockDuration,
        toast: AuthToast.none,
      ),
    );
    _startTicker();
  }

  /// Starts the one-second countdown ticks.
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => add(const AuthTicked()));
  }

  /// Refreshes the remaining lock time and unlocks once it has run out.
  void _onTicked(AuthTicked event, Emitter<AuthState> emit) {
    final until = state.lockedUntil;
    if (until == null) {
      _ticker?.cancel();
      return;
    }
    final left = until.difference(DateTime.now());
    if (left > Duration.zero) {
      emit(state.copyWith(remaining: left));
      return;
    }
    _ticker?.cancel();
    lockRepository.save(null);
    emit(state.copyWith(unlock: true, remaining: Duration.zero, attemptsLeft: AuthState.maxAttempts));
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
