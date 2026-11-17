part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// The toast the sign-in screen shows at its top.
enum AuthToast {
  /// No toast.
  none,

  /// A field is empty (amber).
  empty,

  /// Wrong login or password, worded by the backend (red).
  wrong,
}

/// Everything the sign-in screen renders itself from.
class AuthState extends Equatable {
  /// Lock length assumed when the backend does not say how long sign-in stays locked.
  static const lockDuration = Duration(minutes: 5);

  /// Request lifecycle of the sign-in.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present (unexpected failures); reset by the next emit.
  final ScreenResponse? response;

  /// Login as typed.
  final String login;

  /// Password as typed.
  final String password;

  /// True once "Kirish" was pressed with an empty field, so empty fields turn red.
  final bool showErrors;

  /// True after a rejected sign-in; both fields turn red until the next edit.
  final bool credentialsWrong;

  /// Moment the lock ends; null while the account is not locked.
  final DateTime? lockedUntil;

  /// Lock time left, refreshed every second while locked.
  final Duration remaining;

  /// Toast to show.
  final AuthToast toast;

  /// Backend headline of the wrong-credentials toast; null falls back to the app's own title.
  final String? toastTitle;

  /// Backend sentence of the wrong-credentials toast.
  final String toastMessage;

  /// Counts the toasts requested so far; the screen shows one each time it grows, even when [toast] repeats.
  final int toastSeq;

  /// Builds the initial state.
  const AuthState({
    this.status = ScreenStatus.initial,
    this.response,
    this.login = '',
    this.password = '',
    this.showErrors = false,
    this.credentialsWrong = false,
    this.lockedUntil,
    this.remaining = Duration.zero,
    this.toast = AuthToast.none,
    this.toastTitle,
    this.toastMessage = '',
    this.toastSeq = 0,
  });

  /// Whether the account is locked.
  bool get locked => lockedUntil != null;

  /// Whether the login field is empty.
  bool get loginEmpty => login.trim().isEmpty;

  /// Whether the password field is empty.
  bool get passwordEmpty => password.isEmpty;

  /// Whether the login field is drawn red.
  bool get loginInvalid => credentialsWrong || (showErrors && loginEmpty);

  /// Whether the password field is drawn red.
  bool get passwordInvalid => credentialsWrong || (showErrors && passwordEmpty);

  /// Copies the state, resetting [response] unless a new one is passed so the
  /// same message can fire again on a later emit; [lockedUntil] is cleared with [unlock].
  AuthState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    String? login,
    String? password,
    bool? showErrors,
    bool? credentialsWrong,
    DateTime? lockedUntil,
    bool unlock = false,
    Duration? remaining,
    AuthToast? toast,
    String? toastTitle,
    String? toastMessage,
    int? toastSeq,
  }) => AuthState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    login: login ?? this.login,
    password: password ?? this.password,
    showErrors: showErrors ?? this.showErrors,
    credentialsWrong: credentialsWrong ?? this.credentialsWrong,
    lockedUntil: unlock ? null : (lockedUntil ?? this.lockedUntil),
    remaining: remaining ?? this.remaining,
    toast: toast ?? this.toast,
    toastTitle: toastTitle ?? this.toastTitle,
    toastMessage: toastMessage ?? this.toastMessage,
    toastSeq: toastSeq ?? this.toastSeq,
  );

  @override
  List<Object?> get props => [
    status,
    response,
    login,
    password,
    showErrors,
    credentialsWrong,
    lockedUntil,
    remaining,
    toast,
    toastTitle,
    toastMessage,
    toastSeq,
  ];
}
