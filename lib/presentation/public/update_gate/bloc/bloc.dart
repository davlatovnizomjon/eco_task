import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/update_need.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/update_check.dart';
import 'package:eco_task/infrastructure/repository/app_update_repository.dart';

part 'event.dart';
part 'state.dart';

/// Checks the installed version against the backend's release and remembers which optional update the user
/// postponed, so the dialog appears once per release and run.
class UpdateBloc extends Bloc<UpdateEvent, UpdateState> {
  /// Source of the latest release; owned by the app root.
  final AppUpdateRepository repository;

  /// Wires the handlers.
  UpdateBloc({required this.repository}) : super(const UpdateState()) {
    on<UpdateRequested>(_onRequested);
    on<UpdateDismissed>((event, emit) => emit(state.copyWith(dismissed: event.version)));
  }

  /// Runs the check. The maintenance wall is raised by a server error (5xx) or by the release's `is_maintenance` flag and
  /// lowered by an answer without the flag; any other failure (offline, timeout) must never block the app, so it keeps
  /// the last result and the next launch or resume asks again.
  Future<void> _onRequested(UpdateRequested event, Emitter<UpdateState> emit) async {
    if (state.maintenance) emit(state.copyWith(retrying: true));
    try {
      final check = await repository.check();
      emit(state.copyWith(check: check, maintenance: check.isMaintenance, retrying: false));
    } catch (e) {
      emit(state.copyWith(maintenance: e is ServerErrorResponse || state.maintenance, retrying: false));
    }
  }
}
