import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/infrastructure/dto/models/task_query.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives the tasks list of one staff member: loads their tasks cache-first and keeps the selected tab.
class EmployeeTasksBloc extends Bloc<EmployeeTasksEvent, EmployeeTasksState> {
  /// Data source of every task request; owned by the app root.
  final TasksRepository repository;

  /// Id of the staff member whose tasks are listed.
  final String userId;

  /// Wires the handlers of the screen.
  EmployeeTasksBloc({required this.repository, required this.userId}) : super(const EmployeeTasksState()) {
    on<EmployeeTasksStarted>((event, emit) => _load(emit, refreshing: false));
    on<EmployeeTasksRefreshed>((event, emit) => _load(emit, refreshing: true));
    on<EmployeeTasksTabChanged>((event, emit) => emit(state.copyWith(tab: event.tab)));
  }

  /// Query of the member's tasks: all statuses, newest deadline first.
  TaskQuery get _query => TaskQuery(who: userId);

  /// Emits the cached tasks first (if any), then the fresh ones; an error keeps cached tasks on screen.
  Future<void> _load(Emitter<EmployeeTasksState> emit, {required bool refreshing}) async {
    /// Tasks remembered from an earlier visit.
    final cached = repository.cachedTasks(_query).items;
    emit(
      state.copyWith(
        items: cached,
        refreshing: refreshing,
        status: cached.isEmpty ? ScreenStatus.loading : ScreenStatus.success,
      ),
    );
    try {
      /// Fresh first page of the member's tasks.
      final fresh = await repository.getTasks(_query);
      emit(state.copyWith(items: fresh.items, status: ScreenStatus.success, refreshing: false));
    } catch (e) {
      emit(
        state.copyWith(
          status: state.items.isEmpty ? ScreenStatus.error : ScreenStatus.success,
          refreshing: false,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
        ),
      );
    }
  }
}
