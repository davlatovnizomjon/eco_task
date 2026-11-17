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

  /// Id of the account being edited; null when opening a new one.
  final String? editId;

  /// Wires the handlers of the form.
  MemberFormBloc({required this.repository, required this.client, required this.team, this.editId})
    : super(MemberFormState(password: _generate())) {
    on<MemberFormNameChanged>((event, emit) => emit(state.copyWith(name: event.value)));
    on<MemberFormPhoneChanged>((event, emit) => emit(state.copyWith(phone: event.value)));
    on<MemberFormLoginChanged>((event, emit) => emit(state.copyWith(login: event.value)));
    on<MemberFormPasswordRegenerated>((event, emit) => emit(state.copyWith(password: _generate())));
    on<MemberFormRoleChanged>((event, emit) => emit(state.copyWith(role: event.value)));
    on<MemberFormOrgChanged>((event, emit) => emit(state.copyWith(isOrg: event.isOrg)));
    on<MemberFormAddressChanged>((event, emit) => emit(state.copyWith(address: event.value)));
    on<MemberFormContactChanged>((event, emit) => emit(state.copyWith(contactPerson: event.value)));
    on<MemberFormNoteChanged>((event, emit) => emit(state.copyWith(note: event.value)));
    on<MemberFormStarted>(_onStarted);
    on<MemberFormSubmitted>(_onSubmitted);
  }

  /// Loads the account being edited and fills the form with it.
  Future<void> _onStarted(MemberFormStarted event, Emitter<MemberFormState> emit) async {
    emit(state.copyWith(status: ScreenStatus.loading));
    try {
      final user = await repository.getUser(editId!);
      emit(
        state.copyWith(
          status: ScreenStatus.initial,
          seed: user,
          name: user.name,
          phone: user.phone,
          address: user.team,
          isOrg: user.isOrg,
          contactPerson: user.contactPerson,
          note: user.note,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: ScreenStatus.error, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()),
      );
    }
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
      if (editId != null) {
        final isOrg = client && state.isOrg;
        final saved = await repository.updateUser(editId!, {
          'name': state.name.trim(),
          'phone': PhoneFormatter.apiValue(state.phone),
          if (client) ...{
            'team': state.address.trim(),
            'isOrg': isOrg,
            'contactPerson': isOrg ? state.contactPerson.trim() : '',
            'note': state.note.trim(),
          },
        });
        emit(state.copyWith(status: ScreenStatus.success, created: saved));
        return;
      }
      final created = await repository.addUser(
        NewAccount(
          login: state.login.trim().toLowerCase(),
          name: state.name.trim(),
          phone: PhoneFormatter.apiValue(state.phone),
          role: client ? UserRole.client : state.role,
          team: client ? state.address.trim() : team,
          isOrg: client && state.isOrg,
          contactPerson: client && state.isOrg ? state.contactPerson.trim() : '',
          note: client ? state.note.trim() : '',
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
