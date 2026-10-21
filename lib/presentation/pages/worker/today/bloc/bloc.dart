import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/task_query.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';

part 'event.dart';
part 'state.dart';

/// Drives the worker home: the worker's active tasks, soonest first, served
/// cache-first.
class TodayBloc extends Bloc<TodayEvent, TodayState> {
  /// Data source of task reads; owned by the app root.
  final TasksRepository repository;

  /// The active tasks of the signed-in worker, soonest deadline first.
  static const _query = TaskQuery(group: 'active');

  /// Wires the handlers of the home tab.
  TodayBloc({required this.repository}) : super(const TodayState()) {
    on<TodayStarted>((event, emit) => _load(emit, refreshing: false));
    on<TodayRefreshed>((event, emit) => _load(emit, refreshing: true));
  }

  /// Emits the cached tasks first (if any), then the fresh ones. An error keeps
  /// cached tasks on screen and only surfaces the failure.
  Future<void> _load(Emitter<TodayState> emit, {required bool refreshing}) async {
    final cached = repository.cachedTasks(_query).items;
    emit(
      state.copyWith(
        items: cached,
        refreshing: refreshing,
        status: cached.isEmpty ? ScreenStatus.loading : ScreenStatus.success,
      ),
    );
    try {
      emit(
        state.copyWith(
          items: (await repository.getTasks(_query)).items,
          status: ScreenStatus.success,
          refreshing: false,
        ),
      );
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
