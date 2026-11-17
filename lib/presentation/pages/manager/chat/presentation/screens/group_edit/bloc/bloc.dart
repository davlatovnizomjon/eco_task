import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/conversation_model.dart';
import 'package:eco_task/infrastructure/dto/models/user_ref.dart';
import 'package:eco_task/helpers/media_picker.dart';
import 'package:eco_task/infrastructure/dto/models/file_attachment.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/infrastructure/repository/files_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives the group-edit page: keeps a draft of the title and the member list and applies the differences on save.
class GroupEditBloc extends Bloc<GroupEditEvent, GroupEditState> {
  /// Chat data source; owned by the app root.
  final ChatRepository repository;

  /// Uploads the group photo.
  final FilesRepository files;

  /// Id of the group being edited.
  final String conversationId;

  /// Wires the handlers of the page.
  GroupEditBloc({required this.repository, required this.files, required this.conversationId})
    : super(const GroupEditState()) {
    on<GroupEditStarted>(_onStarted);
    on<GroupEditTitleChanged>((event, emit) => emit(state.copyWith(title: event.title)));
    on<GroupEditMemberRemoved>(
      (event, emit) => emit(
        state.copyWith(
          members: [
            for (final m in state.members)
              if (m.id != event.id) m,
          ],
        ),
      ),
    );
    on<GroupEditMembersAdded>((event, emit) => emit(state.copyWith(members: [...state.members, ...event.people])));
    on<GroupEditPhotoPicked>(_onPhoto);
    on<GroupEditSaved>(_onSaved);
  }

  /// Uploads the picked photo; it is attached to the group when the page is saved.
  Future<void> _onPhoto(GroupEditPhotoPicked event, Emitter<GroupEditState> emit) async {
    emit(state.copyWith(uploading: true));
    try {
      emit(state.copyWith(uploading: false, photo: await files.uploadPicked(event.file)));
    } catch (e) {
      emit(state.copyWith(uploading: false, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }

  /// Loads the group and the people that could be added.
  Future<void> _onStarted(GroupEditStarted event, Emitter<GroupEditState> emit) async {
    emit(state.copyWith(status: ScreenStatus.loading));
    try {
      final group = await repository.getConversation(conversationId);
      final contacts = await repository.getContacts();
      emit(
        state.copyWith(
          original: group,
          title: group.title,
          members: group.members,
          candidates: contacts,
          status: ScreenStatus.success,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: ScreenStatus.error, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()),
      );
    }
  }

  /// Applies the title change, the added and the removed members, in that order; stops at the first failure.
  Future<void> _onSaved(GroupEditSaved event, Emitter<GroupEditState> emit) async {
    final original = state.original;
    if (original == null) return;
    if (state.title.trim().isEmpty) {
      emit(state.copyWith(showErrors: true));
      return;
    }
    emit(state.copyWith(busy: true, showErrors: true));
    try {
      final before = {for (final m in original.members) m.id};
      final after = {for (final m in state.members) m.id};
      final renamed = state.title.trim() != original.title;
      if (renamed || state.photo != null) {
        await repository.updateConversation(
          conversationId,
          title: renamed ? state.title.trim() : null,
          avatarId: state.photo?.id,
        );
      }
      final added = after.difference(before).toList();
      if (added.isNotEmpty) await repository.addMembers(conversationId, added);
      for (final id in before.difference(after)) {
        await repository.removeMember(conversationId, id);
      }
      emit(state.copyWith(busy: false, saved: true));
    } catch (e) {
      emit(state.copyWith(busy: false, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }
}
