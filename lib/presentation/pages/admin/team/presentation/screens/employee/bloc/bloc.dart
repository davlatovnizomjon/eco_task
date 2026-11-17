import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/task_query.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';
import 'package:eco_task/infrastructure/dto/models/app_user.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';

part 'event.dart';
part 'state.dart';

/// Drives one employee's profile: the account and every task they take part
/// in, split into active and history by the screen's tab.
class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  /// Data source of the account; owned by the app root.
  final TeamRepository team;

  /// Data source of the employee's tasks; owned by the app root.
  final TasksRepository tasks;

  /// Id of the employee whose profile is shown.
  final String userId;

  /// Wires the handlers of the profile.
  EmployeeBloc({required this.team, required this.tasks, required this.userId}) : super(const EmployeeState()) {
    on<EmployeeStarted>((event, emit) => _load(emit, refreshing: false));
    on<EmployeeRefreshed>((event, emit) => _load(emit, refreshing: true));
    on<EmployeeDeleted>(_onDeleted);
    on<EmployeeTabChanged>((event, emit) => emit(state.copyWith(tab: event.tab)));
  }

  /// Deletes the account; the screen closes on [EmployeeState.removed].
  Future<void> _onDeleted(EmployeeDeleted event, Emitter<EmployeeState> emit) async {
    emit(state.copyWith(busy: true));
    try {
      emit(state.copyWith(busy: false, removed: await team.deleteUser(userId)));
    } catch (e) {
      emit(state.copyWith(busy: false, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }

  /// Loads the account and the employee's tasks together. Cached tasks are
  /// emitted first; an error keeps whatever is already on screen.
  Future<void> _load(Emitter<EmployeeState> emit, {required bool refreshing}) async {
    final query = TaskQuery(who: userId);
    final cached = tasks.cachedTasks(query).items;
    emit(
      state.copyWith(
        items: cached,
        refreshing: refreshing,
        status: cached.isEmpty && state.user == null ? ScreenStatus.loading : ScreenStatus.success,
      ),
    );
    try {
      final (user, page) = await (team.getUser(userId), tasks.getTasks(query)).wait;
      emit(state.copyWith(user: user, items: page.items, status: ScreenStatus.success, refreshing: false));
    } catch (e) {
      emit(
        state.copyWith(
          status: state.user == null ? ScreenStatus.error : ScreenStatus.success,
          refreshing: false,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
        ),
      );
    }
  }
}
