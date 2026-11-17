import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives the login and password form: validates the fields and saves the login and/or the password.
class LoginChangeBloc extends Bloc<LoginChangeEvent, LoginChangeState> {
  /// Owner of the signed-in account; owned by the app root.
  final SessionRepository session;

  /// Login shown when the form opened; an unchanged login is not sent.
  final String initialLogin;

  /// Starts with [initialLogin] in the login field.
  LoginChangeBloc({required this.session, required this.initialLogin}) : super(LoginChangeState(login: initialLogin)) {
    on<LoginChangeLoginEdited>((event, emit) => emit(state.copyWith(login: event.value)));
    on<LoginChangeCurrentEdited>((event, emit) => emit(state.copyWith(current: event.value)));
    on<LoginChangeNextEdited>((event, emit) => emit(state.copyWith(next: event.value)));
    on<LoginChangeRepeatEdited>((event, emit) => emit(state.copyWith(repeat: event.value)));
    on<LoginChangeSubmitted>(_onSubmitted);
  }

  /// Saves what changed: the login first, then the password. Nothing changed just closes the form.
  Future<void> _onSubmitted(LoginChangeSubmitted event, Emitter<LoginChangeState> emit) async {
    final invalid = state.error;
    if (invalid != null) {
      emit(state.copyWith(response: MessageErrorResponse(invalid)));
      return;
    }
    emit(state.copyWith(status: ScreenStatus.loading));
    try {
      final login = state.login.trim().toLowerCase();
      if (login.isNotEmpty && login != initialLogin) {
        await session.updateAccount(name: session.user.value!.user.name, login: login);
      }
      if (state.next.isNotEmpty) {
        await session.changePassword(oldPassword: state.current, newPassword: state.next);
      }
      emit(state.copyWith(status: ScreenStatus.success, saved: true));
    } catch (e) {
      emit(
        state.copyWith(
          status: ScreenStatus.initial,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
        ),
      );
    }
  }
}
