part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the sign-in screen renders itself from.
class AuthState extends Equatable {
  /// Total sign-in attempts shown before the account is advised to ask the boss.
  static const maxAttempts = 5;

  /// Request lifecycle; `success` means the session is stored — the router's
  /// redirect then replaces this screen with the home (or permission) screen.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present, then reset by the next emit.
  final ScreenResponse? response;

  /// Raw login-field text.
  final String login;

  /// Raw password-field text.
  final String password;

  /// Flipped on the first submit attempt; until then no field turns red.
  final bool showErrors;

  /// True after the backend rejected the credentials; cleared on the next keystroke.
  final bool credentialsWrong;

  /// Attempts remaining, shown in the wrong-credentials banner.
  final int attemptsLeft;

  /// Builds the initial, empty form state.
  const AuthState({
    this.status = ScreenStatus.initial,
    this.response,
    this.login = '',
    this.password = '',
    this.showErrors = false,
    this.credentialsWrong = false,
    this.attemptsLeft = maxAttempts,
  });

  /// Validation message for the login, independent of [showErrors].
  String? get loginError => login.trim().isEmpty ? TrWords.vLoginRequired.tr() : null;

  /// Validation message for the password, independent of [showErrors].
  String? get passwordError => password.isEmpty ? TrWords.vPasswordRequired.tr() : null;

  /// Login error the FIELD should display — nothing before the first submit.
  String? get visibleLoginError => showErrors ? loginError : null;

  /// Password error the FIELD should display — nothing before the first submit.
  String? get visiblePasswordError => showErrors ? passwordError : null;

  /// Copies the state, resetting [response] unless a new one is passed so the
  /// same message can fire again on a later emit.
  AuthState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    String? login,
    String? password,
    bool? showErrors,
    bool? credentialsWrong,
    int? attemptsLeft,
  }) => AuthState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    login: login ?? this.login,
    password: password ?? this.password,
    showErrors: showErrors ?? this.showErrors,
    credentialsWrong: credentialsWrong ?? this.credentialsWrong,
    attemptsLeft: attemptsLeft ?? this.attemptsLeft,
  );

  @override
  List<Object?> get props => [status, response, login, password, showErrors, credentialsWrong, attemptsLeft];
}
