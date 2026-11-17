import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/notifications_repository.dart';
import 'package:eco_task/domain/common/enums/notification_kind.dart';
import 'package:eco_task/infrastructure/dto/models/notification_model.dart';

part 'event.dart';
part 'state.dart';

/// Drives the inbox: a filtered, server-paged list served cache-first, plus the
/// mark-as-read actions.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  /// Data source of the inbox; owned by the app root.
  final NotificationsRepository repository;

  /// Wires the handlers of the inbox.
  NotificationsBloc({required this.repository}) : super(const NotificationsState()) {
    on<NotificationsStarted>((event, emit) => _fetch(emit, refreshing: false));
    on<NotificationsRefreshed>((event, emit) => _fetch(emit, refreshing: true));
    on<NotificationsGroupChanged>((event, emit) {
      emit(state.copyWith(group: event.group, items: const []));
      return _fetch(emit, refreshing: false);
    });
    on<NotificationsMoreRequested>(_onMore);
    on<NotificationsMarkedRead>(_onMarkedRead);
  }

  /// Loads page 1 of the selected group. A non-empty cache is emitted first,
  /// then replaced by the fresh page; a response for a group that is no longer
  /// selected is dropped.
  Future<void> _fetch(Emitter<NotificationsState> emit, {required bool refreshing}) async {
    final group = state.group;
    final cached = repository.cachedInbox(group.name);
    emit(
      state.copyWith(
        items: cached.page.items,
        page: cached.page.page,
        lastPage: cached.page.lastPage,
        refreshing: refreshing,
        status: cached.page.items.isEmpty ? ScreenStatus.loading : ScreenStatus.success,
      ),
    );
    try {
      final fresh = await repository.getInbox(group.name);
      if (state.group != group) return;
      emit(
        state.copyWith(
          items: fresh.page.items,
          page: fresh.page.page,
          lastPage: fresh.page.lastPage,
          status: ScreenStatus.success,
          refreshing: false,
        ),
      );
    } catch (e) {
      if (state.group != group) return;
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
  Future<void> _onMore(NotificationsMoreRequested event, Emitter<NotificationsState> emit) async {
    if (state.isLoadingMore || state.status.isLoading || state.page >= state.lastPage) return;
    final group = state.group;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final next = await repository.getInbox(group.name, page: state.page + 1);
      if (state.group != group) return;
      emit(
        state.copyWith(
          items: [...state.items, ...next.page.items],
          page: next.page.page,
          lastPage: next.page.lastPage,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }

  /// Marks one entry (or all) as read and reloads the list and the badge.
  Future<void> _onMarkedRead(NotificationsMarkedRead event, Emitter<NotificationsState> emit) async {
    try {
      await repository.markRead(id: event.id);
      await _fetch(emit, refreshing: false);
    } catch (e) {
      emit(state.copyWith(response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }
}
