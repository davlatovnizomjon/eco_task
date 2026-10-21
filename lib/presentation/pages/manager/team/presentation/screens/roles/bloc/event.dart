part of 'bloc.dart';

/// Base of every action the roles screen can dispatch.
sealed class RolesEvent {
  /// Allows the events to have const constructors.
  const RolesEvent();
}

/// The screen opened — load the account and its switches.
final class RolesStarted extends RolesEvent {
  /// Fires the load.
  const RolesStarted();
}

/// The admin picked another role.
final class RolesRoleChanged extends RolesEvent {
  /// The chosen role.
  final UserRole role;

  /// Carries the chosen role.
  const RolesRoleChanged(this.role);
}

/// The admin flipped one permission switch.
final class RolesFlagToggled extends RolesEvent {
  /// Key of the switch (`create`, `reward`, ...).
  final String key;

  /// Carries the switch key.
  const RolesFlagToggled(this.key);
}

/// The admin pressed save.
final class RolesSaved extends RolesEvent {
  /// Stores the edited role and switches.
  const RolesSaved();
}
