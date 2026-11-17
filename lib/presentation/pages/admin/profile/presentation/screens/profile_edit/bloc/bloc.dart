import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives the profile edit form: keeps the typed name and saves it to the signed-in account.
class ProfileEditBloc extends Bloc<ProfileEditEvent, ProfileEditState> {
  /// Owner of the signed-in account; owned by the app root.
  final SessionRepository session;

  /// Starts from the current name split into first word and the rest.
  ProfileEditBloc({required this.session})
    : super(
        ProfileEditState(
          first: session.user.value!.user.name.split(' ').first,
          last: session.user.value!.user.name.split(' ').skip(1).join(' '),
        ),
      ) {
    on<ProfileEditFirstChanged>((event, emit) => emit(state.copyWith(first: event.value)));
    on<ProfileEditLastChanged>((event, emit) => emit(state.copyWith(last: event.value)));
    on<ProfileEditSubmitted>(_onSubmitted);
  }

  /// Saves the name; an empty first name is reported without a request.
  Future<void> _onSubmitted(ProfileEditSubmitted event, Emitter<ProfileEditState> emit) async {
    final invalid = state.error;
    if (invalid != null) {
      emit(state.copyWith(response: MessageErrorResponse(invalid)));
      return;
    }
    emit(state.copyWith(status: ScreenStatus.loading));
    try {
      await session.updateAccount(name: '${state.first.trim()} ${state.last.trim()}'.trim());
      emit(state.copyWith(status: ScreenStatus.success, saved: true));
    } catch (e) {
      emit(
        state.copyWith(
          status: ScreenStatus.initial,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
        ),
      );
    }
  }
}
