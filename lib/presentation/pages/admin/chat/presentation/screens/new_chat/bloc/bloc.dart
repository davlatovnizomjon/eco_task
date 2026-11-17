import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/user_ref.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives the new-chat screen: searches the people the signed-in user may
/// write to and opens a direct chat with one of them, or creates a group.
class NewChatBloc extends Bloc<NewChatEvent, NewChatState> {
  /// Data source of chats; owned by the app root.
  final ChatRepository repository;

  /// Wires the handlers of the screen.
  NewChatBloc({required this.repository}) : super(const NewChatState()) {
    on<NewChatStarted>((event, emit) => _load(emit, ''));
    on<NewChatSearched>((event, emit) => _load(emit, event.query.trim()));
    on<NewChatTabChanged>((event, emit) => emit(state.copyWith(group: event.group)));
    on<NewChatMemberToggled>(_onToggled);
    on<NewChatAllToggled>(_onAll);
    on<NewChatPersonPicked>(_onPicked);
    on<NewChatGroupSubmitted>(_onGroup);
  }

  /// Presents a failure of [e].
  ScreenResponse _failure(Object e) => e is ScreenResponse ? e : const UnExpectedErrorResponse();

  /// Loads the contacts matching [query]; an answer for an outdated query is dropped.
  Future<void> _load(Emitter<NewChatState> emit, String query) async {
    emit(state.copyWith(search: query, status: state.contacts.isEmpty ? ScreenStatus.loading : ScreenStatus.success));
    try {
      final contacts = await repository.getContacts(search: query);
      if (query != state.search) return;
      emit(state.copyWith(contacts: contacts, status: ScreenStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: state.contacts.isEmpty ? ScreenStatus.error : ScreenStatus.success,
          response: _failure(e),
        ),
      );
    }
  }

  /// Ticks or unticks a group member.
  void _onToggled(NewChatMemberToggled event, Emitter<NewChatState> emit) {
    final next = {...state.selected};
    if (!next.remove(event.userId)) next.add(event.userId);
    emit(state.copyWith(selected: next));
  }

  /// Selects every listed contact, or clears the selection when all are already selected.
  void _onAll(NewChatAllToggled event, Emitter<NewChatState> emit) {
    final all = {for (final c in state.contacts) c.id};
    emit(state.copyWith(selected: state.selected.containsAll(all) ? <String>{} : all));
  }

  /// Opens (or reuses) the direct chat with the picked person.
  Future<void> _onPicked(NewChatPersonPicked event, Emitter<NewChatState> emit) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      final chat = await repository.openDirect(event.userId);
      emit(state.copyWith(busy: false, openedId: chat.id));
    } catch (e) {
      emit(state.copyWith(busy: false, response: _failure(e)));
    }
  }

  /// Creates the group from the ticked people.
  Future<void> _onGroup(NewChatGroupSubmitted event, Emitter<NewChatState> emit) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    try {
      final chat = await repository.createGroup(event.title.trim(), state.selected.toList());
      emit(state.copyWith(busy: false, openedId: chat.id));
    } catch (e) {
      emit(state.copyWith(busy: false, response: _failure(e)));
    }
  }
}
