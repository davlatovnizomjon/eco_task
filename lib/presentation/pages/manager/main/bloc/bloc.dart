import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/notifications_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives the role shell: keeps the notifications tab badge in sync by
/// reading the unread counter when the shell opens.
class MainBloc extends Bloc<MainEvent, MainState> {
  /// Owner of the reactive unread counter; owned by the app root.
  final NotificationsRepository repository;

  /// Wires the handlers of the shell.
  MainBloc({required this.repository}) : super(const MainState()) {
    on<MainStarted>(_onStarted);
  }

  /// Refreshes the unread counter; a failure is surfaced but never blocks the tabs.
  Future<void> _onStarted(MainStarted event, Emitter<MainState> emit) async {
    try {
      await repository.refreshUnread();
    } catch (e) {
      emit(state.copyWith(response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }
}
