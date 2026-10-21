import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/conversation_model.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives the chat tab: the signed-in user's conversations, served cache-first
/// with pull-to-refresh. The repository also publishes the total unread count
/// the bottom navigation badge shows.
class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  /// Data source of chats; owned by the app root.
  final ChatRepository repository;

  /// Wires the handlers of the list.
  ChatsBloc({required this.repository}) : super(const ChatsState()) {
    on<ChatsStarted>((event, emit) => _fetch(emit, refreshing: false));
    on<ChatsRefreshed>((event, emit) => _fetch(emit, refreshing: true));
  }

  /// Loads the list. A non-empty cache is emitted first, then replaced by the
  /// fresh list; an error keeps a non-empty cache on screen.
  Future<void> _fetch(Emitter<ChatsState> emit, {required bool refreshing}) async {
    final cached = repository.cachedConversations();
    emit(
      state.copyWith(
        items: cached,
        refreshing: refreshing,
        status: cached.isEmpty ? ScreenStatus.loading : ScreenStatus.success,
      ),
    );
    try {
      emit(state.copyWith(items: await repository.getConversations(), status: ScreenStatus.success, refreshing: false));
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
