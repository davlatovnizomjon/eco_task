part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the role shell renders itself from (the badge itself is the
/// repository's reactive counter, not part of this state).
class MainState extends Equatable {
  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// Builds the initial state.
  const MainState({this.response});

  /// Copies the state, resetting [response] unless a new one is passed so the
  /// same message can fire again on a later emit.
  MainState copyWith({Object? response = _absent}) =>
      MainState(response: identical(response, _absent) ? null : response as ScreenResponse?);

  @override
  List<Object?> get props => [response];
}
