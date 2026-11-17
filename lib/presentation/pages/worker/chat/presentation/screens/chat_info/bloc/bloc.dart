import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/chat_kind.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/app_user.dart';
import 'package:eco_task/infrastructure/dto/models/conversation_model.dart';
import 'package:eco_task/infrastructure/dto/models/task_query.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives the chat-info page: loads the conversation (and, for a direct chat, the other person's account and active
/// task count), switches the caller's mute and lets them leave a group.
class ChatInfoBloc extends Bloc<ChatInfoEvent, ChatInfoState> {
  /// Chat data source; owned by the app root.
  final ChatRepository repository;

  /// Source of the other person's account.
  final TeamRepository team;

  /// Source of the other person's task count.
  final TasksRepository tasks;

  /// Id of the signed-in person.
  final String meId;

  /// Id of the conversation described.
  final String conversationId;

  /// Wires the handlers of the page.
  ChatInfoBloc({
    required this.repository,
    required this.team,
    required this.tasks,
    required this.meId,
    required this.conversationId,
  }) : super(const ChatInfoState()) {
    on<ChatInfoStarted>(_onStarted);
    on<ChatInfoMuteToggled>(_onMute);
    on<ChatInfoLeft>(_onLeft);
  }

  /// Loads the conversation, then the extras a direct chat shows.
  Future<void> _onStarted(ChatInfoStarted event, Emitter<ChatInfoState> emit) async {
    emit(state.copyWith(status: ScreenStatus.loading));
    try {
      final conversation = await repository.getConversation(conversationId);
      emit(state.copyWith(conversation: conversation, status: ScreenStatus.success));
      final other = conversation.other(meId);
      if (conversation.kind == ChatKind.direct && other != null) {
        try {
          final results = await Future.wait<Object>([
            team.getUser(other.id),
            tasks.getTasks(TaskQuery(who: other.id, statuses: {TaskStatus.fresh, TaskStatus.prog})),
          ]);
          emit(state.copyWith(person: results[0] as AppUser, activeTasks: (results[1] as dynamic).total as int));
        } catch (_) {
          // This role may not read the other person's account or task count: the page shows what the chat knows.
        }
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: state.conversation == null ? ScreenStatus.error : ScreenStatus.success,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
        ),
      );
    }
  }

  /// Switches the caller's notifications for this conversation.
  Future<void> _onMute(ChatInfoMuteToggled event, Emitter<ChatInfoState> emit) async {
    final current = state.conversation;
    if (current == null) return;
    emit(state.copyWith(conversation: current.copyWith(muted: !current.muted)));
    try {
      emit(state.copyWith(conversation: await repository.updateConversation(conversationId, muted: !current.muted)));
    } catch (e) {
      emit(state.copyWith(conversation: current, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }

  /// Leaves the group; the page asks the screen to close afterwards.
  Future<void> _onLeft(ChatInfoLeft event, Emitter<ChatInfoState> emit) async {
    emit(state.copyWith(busy: true));
    try {
      await repository.removeMember(conversationId, meId);
      emit(state.copyWith(busy: false, left: true));
    } catch (e) {
      emit(state.copyWith(busy: false, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }
}
