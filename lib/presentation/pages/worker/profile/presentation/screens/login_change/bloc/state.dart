part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the login and password form renders itself from.
class LoginChangeState extends Equatable {
  /// Request lifecycle of the save.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// Login as typed.
  final String login;

  /// Current password as typed.
  final String current;

  /// New password as typed.
  final String next;

  /// Repeated new password as typed.
  final String repeat;

  /// True once the form was saved and the screen should close.
  final bool saved;

  /// Builds the state.
  const LoginChangeState({
    this.status = ScreenStatus.initial,
    this.response,
    this.login = '',
    this.current = '',
    this.next = '',
    this.repeat = '',
    this.saved = false,
  });

  /// First validation message, or null when the form may be saved. A password change needs the current password,
  /// at least 8 characters and a matching repeat; leaving the new password empty only changes the login.
  String? get error {
    if (next.isEmpty) return null;
    if (current.isEmpty) return TrWords.accNeedCurrent.tr();
    if (next.length < 8) return TrWords.accTooShort.tr();
    if (next != repeat) return TrWords.accMismatch.tr();
    return null;
  }

  /// Copies the state, resetting [response] unless a new one is passed so the
  /// same message can fire again on a later emit.
  LoginChangeState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    String? login,
    String? current,
    String? next,
    String? repeat,
    bool saved = false,
  }) => LoginChangeState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    login: login ?? this.login,
    current: current ?? this.current,
    next: next ?? this.next,
    repeat: repeat ?? this.repeat,
    saved: saved,
  );

  @override
  List<Object?> get props => [status, response, login, current, next, repeat, saved];
}
