part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the roles screen renders itself from.
class RolesState extends Equatable {
  /// Request lifecycle of the load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// The staff member; null until the first answer.
  final AppUser? user;

  /// The editable role and switches; null until the first answer.
  final PermissionsModel? permissions;

  /// True while the save request runs.
  final bool busy;

  /// One-shot: the edits were saved and the screen should close.
  final bool saved;

  /// Builds the initial state.
  const RolesState({
    this.status = ScreenStatus.initial,
    this.response,
    this.user,
    this.permissions,
    this.busy = false,
    this.saved = false,
  });

  /// Copies the state; [response] and [saved] reset unless passed, so each
  /// fires once per emit.
  RolesState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    AppUser? user,
    PermissionsModel? permissions,
    bool? busy,
    bool saved = false,
  }) => RolesState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    user: user ?? this.user,
    permissions: permissions ?? this.permissions,
    busy: busy ?? this.busy,
    saved: saved,
  );

  @override
  List<Object?> get props => [status, response, user, permissions, busy, saved];
}
