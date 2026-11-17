part of 'bloc.dart';

/// Base of every action the update gate can dispatch.
sealed class UpdateEvent {
  /// Allows the events to have const constructors.
  const UpdateEvent();
}

/// The app started or came back to the foreground: ask the backend for the latest release.
final class UpdateRequested extends UpdateEvent {
  /// Starts a check.
  const UpdateRequested();
}

/// The user chose "later" on the optional-update dialog.
final class UpdateDismissed extends UpdateEvent {
  /// Release version that was postponed.
  final String version;

  /// Remembers [version] as postponed.
  const UpdateDismissed(this.version);
}
