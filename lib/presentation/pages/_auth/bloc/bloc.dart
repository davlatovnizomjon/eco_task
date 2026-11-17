import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/login_lock_repository.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives the sign-in screen: validates the fields and signs in. Wrong credentials and the lock come from the backend
/// (its own title/message, and `retry_after` for how long the lock lasts); the app counts nothing itself. While locked
/// the countdown ticks every second. The end of the lock is remembered on the device, so a lock
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
    return AuthState(lockedUntil: until, remaining: until.difference(DateTime.now()));
  }

  /// Signs in. A locked account is ignored (the screen shows the lock banner and a disabled button) and an empty field
  /// is answered with an amber toast, both without a request; a 401 shows the backend's wording in a red toast and a
  /// 429 locks sign-in for the time the backend names.
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
      final failure = e is MessageErrorResponse ? e : null;
      if (failure?.statusCode == 429) {
        _lock(emit, Duration(seconds: failure!.retryAfter ?? AuthState.lockDuration.inSeconds));
      } else if (failure?.statusCode == 401) {
        emit(
          state.copyWith(
            status: ScreenStatus.initial,
            credentialsWrong: true,
            toast: AuthToast.wrong,
            toastTitle: failure!.title,
            toastMessage: failure.message,
            toastSeq: state.toastSeq + 1,
          ),
        );
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

  /// Locks sign-in for [duration] and starts the countdown.
  void _lock(Emitter<AuthState> emit, Duration duration) {
    final until = DateTime.now().add(duration);
    lockRepository.save(until);
    emit(
      state.copyWith(
        status: ScreenStatus.initial,
        credentialsWrong: false,
        lockedUntil: until,
        remaining: duration,
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
    emit(state.copyWith(unlock: true, remaining: Duration.zero));
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
