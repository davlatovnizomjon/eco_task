import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';
import 'package:eco_task/infrastructure/dto/models/app_user.dart';

part 'event.dart';
part 'state.dart';

/// Drives the team directory: a staff tab and a clients tab, each a
/// server-paged, searchable list served cache-first.
class TeamBloc extends Bloc<TeamEvent, TeamState> {
  /// Data source of the directory; owned by the app root.
  final TeamRepository repository;

  /// Wires the handlers of the directory.
  TeamBloc({required this.repository}) : super(const TeamState()) {
    on<TeamStarted>((event, emit) => _fetch(emit, refreshing: false));
    on<TeamRefreshed>((event, emit) => _fetch(emit, refreshing: true));
    on<TeamTabChanged>((event, emit) {
      emit(state.copyWith(clients: event.clients, search: '', items: const []));
      return _fetch(emit, refreshing: false);
    });
    on<TeamSearchChanged>((event, emit) {
      emit(state.copyWith(search: event.text));
      return _fetch(emit, refreshing: false);
    });
    on<TeamMoreRequested>(_onMore);
  }

  /// Loads page 1 for the current tab and search. A non-empty cache is emitted
  /// first, then replaced by the fresh page; a response for a tab/search that
  /// is no longer current is dropped.
  Future<void> _fetch(Emitter<TeamState> emit, {required bool refreshing}) async {
    final (clients, search) = (state.clients, state.search);
    final cached = repository.cachedUsers(clients: clients, search: search);
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
      final fresh = await repository.getUsers(clients: clients, search: search);
      if (state.clients != clients || state.search != search) return;
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
      if (state.clients != clients || state.search != search) return;
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
  Future<void> _onMore(TeamMoreRequested event, Emitter<TeamState> emit) async {
    if (state.isLoadingMore || state.status.isLoading || state.page >= state.lastPage) return;
    final (clients, search) = (state.clients, state.search);
    emit(state.copyWith(isLoadingMore: true));
    try {
      final next = await repository.getUsers(clients: clients, search: search, page: state.page + 1);
      if (state.clients != clients || state.search != search) return;
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
