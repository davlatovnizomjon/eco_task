import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/legal_kind.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/legal_document.dart';
import 'package:eco_task/infrastructure/repository/legal_repository.dart';

part 'event.dart';
part 'state.dart';

/// Loads one legal text for its sheet: at once when it was fetched before in this language, otherwise from the backend.
class LegalBloc extends Bloc<LegalEvent, LegalState> {
  /// Data source of the legal texts; owned by the app root.
  final LegalRepository repository;

  /// Which text this sheet shows.
  final LegalKind kind;

  /// Wires the handlers of the sheet.
  LegalBloc({required this.repository, required this.kind}) : super(const LegalState()) {
    on<LegalStarted>(_onStarted);
  }

  /// Emits the remembered text, or loads it: spinner, then the text, "not published" (no document) or a retry-able
  /// error.
  Future<void> _onStarted(LegalStarted event, Emitter<LegalState> emit) async {
    final cached = repository.cached(kind);
    if (cached != null) {
      emit(state.copyWith(status: ScreenStatus.success, document: cached));
      return;
    }
    emit(state.copyWith(status: ScreenStatus.loading));
    try {
      final document = await repository.get(kind);
      emit(state.copyWith(status: ScreenStatus.success, document: document));
    } catch (e) {
      emit(
        state.copyWith(status: ScreenStatus.error, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()),
      );
    }
  }
}
