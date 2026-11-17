import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/support_contact.dart';
import 'package:eco_task/infrastructure/repository/support_repository.dart';

part 'event.dart';
part 'state.dart';

/// Loads the dispatcher contacts each time the help sheet opens.
class SupportBloc extends Bloc<SupportEvent, SupportState> {
  /// Data source of the contacts; owned by the app root.
  final SupportRepository repository;

  /// Shortest time the loading spinner is shown.
  static const minLoading = Duration(milliseconds: 600);

  /// Wires the handlers of the sheet.
  SupportBloc({required this.repository}) : super(const SupportState()) {
    on<SupportStarted>(_onStarted);
  }

  /// Shows the contacts at once when an earlier opening already fetched them; otherwise requests them: spinner first,
  /// then the contacts (possibly empty) or a retry-able error.
  Future<void> _onStarted(SupportStarted event, Emitter<SupportState> emit) async {
    final cached = repository.cached;
    if (cached != null) {
      emit(state.copyWith(status: ScreenStatus.success, contact: cached));
      return;
    }
    emit(state.copyWith(status: ScreenStatus.loading));
    try {
      // The spinner stays for at least [minLoading], so a fast answer does not flash by while the sheet slides open.
      final (contact, _) = await (repository.getContact(), Future<void>.delayed(minLoading)).wait;
      emit(state.copyWith(status: ScreenStatus.success, contact: contact));
    } catch (e) {
      emit(
        state.copyWith(status: ScreenStatus.error, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()),
      );
    }
  }
}
