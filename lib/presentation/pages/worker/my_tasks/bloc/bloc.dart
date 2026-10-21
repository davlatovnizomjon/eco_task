import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/task_sort.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/task_query.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';

part 'event.dart';
part 'state.dart';

/// Drives the worker's task list: an active tab and a history tab, each a
/// server-paged list served cache-first.
class MyTasksBloc extends Bloc<MyTasksEvent, MyTasksState> {
  /// Data source of task reads; owned by the app root.
  final TasksRepository repository;

  /// Wires the handlers of the list; [historyFirst] opens on the history tab.
  MyTasksBloc({required this.repository, bool historyFirst = false}) : super(MyTasksState(tab: historyFirst ? 1 : 0)) {
    on<MyTasksStarted>((event, emit) => _fetch(emit, refreshing: false));
    on<MyTasksRefreshed>((event, emit) => _fetch(emit, refreshing: true));
    on<MyTasksTabChanged>((event, emit) {
      emit(state.copyWith(tab: event.tab, items: const []));
      return _fetch(emit, refreshing: false);
    });
    on<MyTasksMoreRequested>(_onMore);
  }

  /// The query of tab [tab]: active tasks soonest first, history newest first.
  static TaskQuery queryOf(int tab) =>
      tab == 0 ? const TaskQuery(group: 'active') : const TaskQuery(group: 'history', sort: TaskSort.created);

  /// Loads page 1 of the current tab. A non-empty cache is emitted first, then
  /// replaced by the fresh page; a response for a tab that is no longer
  /// selected is dropped.
  Future<void> _fetch(Emitter<MyTasksState> emit, {required bool refreshing}) async {
    final tab = state.tab;
    final query = queryOf(tab);
    final cached = repository.cachedTasks(query);
    emit(
      state.copyWith(
        items: cached.items,
        page: cached.page,
        lastPage: cached.lastPage,
        refreshing: refreshing,
        status: cached.items.isEmpty ? ScreenStatus.loading : ScreenStatus.success,
      ),
    );
    try {
      final fresh = await repository.getTasks(query);
      if (state.tab != tab) return;
      emit(
        state.copyWith(
          items: fresh.items,
          page: fresh.page,
          lastPage: fresh.lastPage,
          status: ScreenStatus.success,
          refreshing: false,
        ),
      );
    } catch (e) {
      if (state.tab != tab) return;
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
  Future<void> _onMore(MyTasksMoreRequested event, Emitter<MyTasksState> emit) async {
    if (state.isLoadingMore || state.status.isLoading || state.page >= state.lastPage) return;
    final tab = state.tab;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final next = await repository.getTasks(queryOf(tab), page: state.page + 1);
      if (state.tab != tab) return;
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
