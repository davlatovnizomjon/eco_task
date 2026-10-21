import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/new_account.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';
import 'package:eco_task/utils/formatters/phone_formatter.dart';
import 'package:eco_task/infrastructure/dto/models/app_user.dart';

part 'event.dart';
part 'state.dart';

/// Drives the "open an account" form for staff or clients: keeps every typed
/// value, generates the temporary password, validates on submit and creates the
/// account through [TeamRepository].
class MemberFormBloc extends Bloc<MemberFormEvent, MemberFormState> {
  /// Data source of account creation; owned by the app root.
  final TeamRepository repository;

  /// True when a client account is being opened, false for staff.
  final bool client;

  /// Team a new staff member joins (the boss's own team).
  final String team;

  /// Wires the handlers of the form.
  MemberFormBloc({required this.repository, required this.client, required this.team})
    : super(MemberFormState(password: _generate())) {
    on<MemberFormNameChanged>((event, emit) => emit(state.copyWith(name: event.value)));
    on<MemberFormPhoneChanged>((event, emit) => emit(state.copyWith(phone: event.value)));
    on<MemberFormLoginChanged>((event, emit) => emit(state.copyWith(login: event.value)));
    on<MemberFormPasswordRegenerated>((event, emit) => emit(state.copyWith(password: _generate())));
    on<MemberFormRoleChanged>((event, emit) => emit(state.copyWith(role: event.value)));
    on<MemberFormAddressChanged>((event, emit) => emit(state.copyWith(address: event.value)));
    on<MemberFormSubmitted>(_onSubmitted);
  }

  /// A random 4-digit + 1-letter temporary password.
  static String _generate() {
    final random = Random();
    return '${1000 + random.nextInt(9000)}${String.fromCharCode(97 + random.nextInt(26))}';
  }

  /// Validates, then opens the account. A failed validation emits the FIRST
  /// invalid field's message and flips `showErrors`; nothing is sent.
  Future<void> _onSubmitted(MemberFormSubmitted event, Emitter<MemberFormState> emit) async {
    final invalid = state.nameError ?? state.loginError ?? state.phoneError;
    if (invalid != null) {
      emit(state.copyWith(showErrors: true, response: MessageErrorResponse(invalid)));
      return;
    }
    emit(state.copyWith(status: ScreenStatus.loading, showErrors: true));
    try {
      final created = await repository.addUser(
        NewAccount(
          login: state.login.trim().toLowerCase(),
          name: state.name.trim(),
          phone: PhoneFormatter.apiValue(state.phone),
          role: client ? UserRole.client : state.role,
          team: client ? state.address.trim() : team,
          password: state.password,
        ),
      );
      emit(state.copyWith(status: ScreenStatus.success, created: created));
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
