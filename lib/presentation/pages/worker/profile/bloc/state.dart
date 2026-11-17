part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from "set it to null".
const _absent = Object();

/// Everything the profile tab renders itself from.
class ProfileState extends Equatable {
  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// Dispatcher contacts of the help sheet (cached or fresh); null until the first answer.
  final SupportContact? contact;

  /// True while a refresh is in flight; pull-to-refresh awaits it.
  final bool refreshing;

  /// True from the confirmed sign-out until the session is gone; the confirm dialog awaits it.
  final bool signingOut;

  /// Builds the initial state.
  const ProfileState({this.response, this.contact, this.refreshing = false, this.signingOut = false});

  /// Copies the state, resetting [response] unless a new one is passed so it fires once.
  ProfileState copyWith({Object? response = _absent, SupportContact? contact, bool? refreshing, bool? signingOut}) =>
      ProfileState(
        response: identical(response, _absent) ? null : response as ScreenResponse?,
        contact: contact ?? this.contact,
        refreshing: refreshing ?? this.refreshing,
        signingOut: signingOut ?? this.signingOut,
      );

  @override
  List<Object?> get props => [response, contact, refreshing, signingOut];
}
