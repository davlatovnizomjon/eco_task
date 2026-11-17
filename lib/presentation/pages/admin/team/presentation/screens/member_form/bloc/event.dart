part of 'bloc.dart';

/// Base of every action the account form can dispatch.
sealed class MemberFormEvent {
  /// Allows the events to have const constructors.
  const MemberFormEvent();
}

/// The user typed in the name field.
final class MemberFormNameChanged extends MemberFormEvent {
  /// Raw field text.
  final String value;

  /// Carries the new name.
  const MemberFormNameChanged(this.value);
}

/// The user typed in the phone field.
final class MemberFormPhoneChanged extends MemberFormEvent {
  /// Raw (masked) field text.
  final String value;

  /// Carries the new phone text.
  const MemberFormPhoneChanged(this.value);
}

/// The user typed in the login field.
final class MemberFormLoginChanged extends MemberFormEvent {
  /// Raw field text.
  final String value;

  /// Carries the new login.
  const MemberFormLoginChanged(this.value);
}

/// The user asked for a fresh temporary password.
final class MemberFormPasswordRegenerated extends MemberFormEvent {
  /// Generates a new random password.
  const MemberFormPasswordRegenerated();
}

/// The user picked a staff role.
final class MemberFormRoleChanged extends MemberFormEvent {
  /// The chosen role (worker or manager).
  final UserRole value;

  /// Carries the chosen role.
  const MemberFormRoleChanged(this.value);
}

/// The client type switch was tapped.
final class MemberFormOrgChanged extends MemberFormEvent {
  /// True for an organization, false for a private person.
  final bool isOrg;

  /// Carries the picked type.
  const MemberFormOrgChanged({required this.isOrg});
}

/// The user typed in the optional address field (clients).

final class MemberFormAddressChanged extends MemberFormEvent {
  /// Raw field text.
  final String value;

  /// Carries the new address.
  const MemberFormAddressChanged(this.value);
}

/// The user pressed "open account".
final class MemberFormSubmitted extends MemberFormEvent {
  /// Triggers validation and, if it passes, the create request.
  const MemberFormSubmitted();
}

/// The user typed in the contact-person field (organization clients).
final class MemberFormContactChanged extends MemberFormEvent {
  /// New text.
  final String value;

  /// Carries the text.
  const MemberFormContactChanged(this.value);
}

/// The user typed in the note field (clients).
final class MemberFormNoteChanged extends MemberFormEvent {
  /// New text.
  final String value;

  /// Carries the text.
  const MemberFormNoteChanged(this.value);
}

/// Edit mode opened: load the account and fill the form with it.
final class MemberFormStarted extends MemberFormEvent {
  /// Fires the load.
  const MemberFormStarted();
}
