part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the profile edit form renders itself from.
class ProfileEditState extends Equatable {
  /// Request lifecycle of the save.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// First name as typed.
  final String first;

  /// Last name as typed.
  final String last;

  /// True once the form was saved and the screen should close.
  final bool saved;

  /// Builds the state.
  const ProfileEditState({
    this.status = ScreenStatus.initial,
    this.response,
    this.first = '',
    this.last = '',
    this.saved = false,
  });

  /// Message for an empty name, or null when the form is valid.
  String? get error => first.trim().isEmpty ? TrWords.vNameRequired.tr() : null;

  /// Copies the state, resetting [response] unless a new one is passed so the
  /// same message can fire again on a later emit.
  ProfileEditState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    String? first,
    String? last,
    bool saved = false,
  }) => ProfileEditState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    first: first ?? this.first,
    last: last ?? this.last,
    saved: saved,
  );

  @override
  List<Object?> get props => [status, response, first, last, saved];
}
