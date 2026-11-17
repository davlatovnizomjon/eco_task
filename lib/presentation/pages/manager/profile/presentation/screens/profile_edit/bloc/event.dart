part of 'bloc.dart';

/// Base of every action the profile edit form can dispatch.
sealed class ProfileEditEvent {
  /// Allows the events to have const constructors.
  const ProfileEditEvent();
}

/// The first name was edited.
final class ProfileEditFirstChanged extends ProfileEditEvent {
  /// New first name text.
  final String value;

  /// Stores [value].
  const ProfileEditFirstChanged(this.value);
}

/// The last name was edited.
final class ProfileEditLastChanged extends ProfileEditEvent {
  /// New last name text.
  final String value;

  /// Stores [value].
  const ProfileEditLastChanged(this.value);
}

/// "Save" was pressed.
final class ProfileEditSubmitted extends ProfileEditEvent {
  /// Validates and saves the name.
  const ProfileEditSubmitted();
}
