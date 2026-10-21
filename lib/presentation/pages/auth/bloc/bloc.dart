import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives the sign-in form: keeps the typed values, validates them on submit,
/// and delegates the actual sign-in to the app-wide [SessionRepository] — this
/// feature owns no repository of its own. The role of the account is read from
/// the answer by the router, never decided here.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// App-wide session; the only thing allowed to store a token.
  final SessionRepository repository;

  /// Wires the handlers for the sign-in form.
  AuthBloc({required this.repository}) : super(const AuthState()) {
    on<AuthLoginChanged>((event, emit) => emit(state.copyWith(login: event.login, credentialsWrong: false)));
    on<AuthPasswordChanged>((event, emit) => emit(state.copyWith(password: event.password, credentialsWrong: false)));
    on<AuthSubmitted>(_onSubmitted);
  }

  /// Validates both fields, then signs in.
  ///
  /// A failed validation emits the FIRST invalid field's message as a
  /// [MessageErrorResponse] and flips `showErrors`, so one dialog opens while
  /// every invalid field turns red. A 401 from the backend means wrong
  /// credentials: the fields turn red, the attempt counter drops and the
  /// inline banner shows — no dialog. Anything else goes to the shared dialog.
  Future<void> _onSubmitted(AuthSubmitted event, Emitter<AuthState> emit) async {
    final invalid = state.loginError ?? state.passwordError;
    if (invalid != null) {
      emit(state.copyWith(showErrors: true, response: MessageErrorResponse(invalid)));
      return;
    }
    emit(state.copyWith(status: ScreenStatus.loading, showErrors: true));
    try {
      await repository.login(login: state.login.trim(), password: state.password);
      emit(state.copyWith(status: ScreenStatus.success));
    } catch (e) {
      final wrong = e is MessageErrorResponse && e.statusCode == 401;
      emit(
        state.copyWith(
          status: ScreenStatus.initial,
          credentialsWrong: wrong,
          attemptsLeft: wrong ? (state.attemptsLeft - 1).clamp(0, AuthState.maxAttempts) : state.attemptsLeft,
          response: wrong ? null : (e is ScreenResponse ? e : const UnExpectedErrorResponse()),
        ),
      );
    }
  }
}
