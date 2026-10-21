import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/infrastructure/repository/session_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives the client-bot screen: its only action is signing out.
class ClientBotBloc extends Bloc<ClientBotEvent, ClientBotState> {
  /// Owner of the signed-in identity; owned by the app root.
  final SessionRepository session;

  /// Wires the handler.
  ClientBotBloc({required this.session}) : super(const ClientBotState()) {
    on<ClientBotSignedOut>((event, emit) => session.clearSession());
  }
}
