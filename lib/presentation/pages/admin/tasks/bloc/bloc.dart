import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/task_query.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';

part 'event.dart';
part 'state.dart';

/// Drives the boss task list: server-paged items for the current search and
/// filter, served cache-first, with pull-to-refresh and load-more.
class TasksBloc extends Bloc<TasksEvent, TasksState> {
  /// Data source of every task request; owned by the app root.
  final TasksRepository repository;

  /// Wires the handlers of the list.
  TasksBloc({required this.repository}) : super(const TasksState()) {
    on<TasksStarted>((event, emit) => _fetch(emit, state.query, refreshing: false));
    on<TasksRefreshed>((event, emit) => _fetch(emit, state.query, refreshing: true));
    on<TasksQueryChanged>((event, emit) => _fetch(emit, event.query, refreshing: false));
    on<TasksMoreRequested>(_onMore);
  }

  /// Loads page 1 of [query]. A non-empty cache is emitted first as `success`,
  /// then replaced by the fresh page; an error keeps a non-empty cache on
  /// screen. A response for a query that is no longer current is dropped.
  Future<void> _fetch(Emitter<TasksState> emit, TaskQuery query, {required bool refreshing}) async {
    final cached = repository.cachedTasks(query);
    emit(
      state.copyWith(
        query: query,
        refreshing: refreshing,
        status: cached.items.isEmpty ? ScreenStatus.loading : ScreenStatus.success,
        items: cached.items,
        page: cached.page,
        lastPage: cached.lastPage,
      ),
    );
    try {
      final fresh = await repository.getTasks(query);
      // A newer query was dispatched while this one was in flight.
      if (state.query.cacheKey != query.cacheKey) return;
      emit(
        state.copyWith(
          status: ScreenStatus.success,
          items: fresh.items,
          page: fresh.page,
          lastPage: fresh.lastPage,
          refreshing: false,
        ),
      );
    } catch (e) {
      if (state.query.cacheKey != query.cacheKey) return;
      emit(
        state.copyWith(
          status: state.items.isEmpty ? ScreenStatus.error : ScreenStatus.success,
          refreshing: false,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
        ),
      );
    }
  }

  /// Appends the next page; ignored while a fetch runs or on the last page.
  Future<void> _onMore(TasksMoreRequested event, Emitter<TasksState> emit) async {
    if (state.isLoadingMore || state.status.isLoading || state.page >= state.lastPage) return;
    final query = state.query;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final next = await repository.getTasks(query, page: state.page + 1);
      if (state.query.cacheKey != query.cacheKey) return;
      emit(
        state.copyWith(
          items: [...state.items, ...next.items],
          page: next.page,
          lastPage: next.lastPage,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }
}
