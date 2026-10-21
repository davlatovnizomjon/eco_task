import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/infrastructure/dto/models/app_user.dart';
import 'package:eco_task/infrastructure/dto/models/permissions_model.dart';

part 'event.dart';
part 'state.dart';

/// Drives the role and permissions screen: loads the account and its switches,
/// keeps the edits locally and saves them on demand.
class RolesBloc extends Bloc<RolesEvent, RolesState> {
  /// Data source of accounts and permissions; owned by the app root.
  final TeamRepository repository;

  /// Id of the staff member being edited.
  final String userId;

  /// Wires the handlers of the screen.
  RolesBloc({required this.repository, required this.userId}) : super(const RolesState()) {
    on<RolesStarted>(_onStarted);
    on<RolesRoleChanged>(
      (event, emit) => emit(state.copyWith(permissions: state.permissions?.copyWith(role: event.role))),
    );
    on<RolesFlagToggled>((event, emit) {
      final current = state.permissions;
      if (current == null) return;
      emit(
        state.copyWith(
          permissions: current.copyWith(flags: {...current.flags, event.key: !(current.flags[event.key] ?? false)}),
        ),
      );
    });
    on<RolesSaved>(_onSaved);
  }

  /// Loads the account and its permission switches together.
  Future<void> _onStarted(RolesStarted event, Emitter<RolesState> emit) async {
    emit(state.copyWith(status: ScreenStatus.loading));
    try {
      final (user, permissions) = await (repository.getUser(userId), repository.getPermissions(userId)).wait;
      emit(state.copyWith(user: user, permissions: permissions, status: ScreenStatus.success));
    } catch (e) {
      emit(
        state.copyWith(status: ScreenStatus.error, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()),
      );
    }
  }

  /// Saves the edited role and switches.
  Future<void> _onSaved(RolesSaved event, Emitter<RolesState> emit) async {
    final current = state.permissions;
    if (current == null) return;
    emit(state.copyWith(busy: true));
    try {
      emit(state.copyWith(permissions: await repository.savePermissions(current), busy: false, saved: true));
    } catch (e) {
      emit(state.copyWith(busy: false, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }
}
