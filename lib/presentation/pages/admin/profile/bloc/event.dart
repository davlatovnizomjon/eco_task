part of 'bloc.dart';

/// Base of every action the profile tab can dispatch.
sealed class ProfileEvent {
  /// Allows the events to have const constructors.
  const ProfileEvent();
}

/// The tab opened — load the summary numbers.
final class ProfileStarted extends ProfileEvent {
  /// Fires the first load.
  const ProfileStarted();
}

/// Pull-to-refresh — reload the summary numbers.
final class ProfileRefreshed extends ProfileEvent {
  /// Reloads while keeping the current numbers visible.
  const ProfileRefreshed();
}

/// The user confirmed signing out.
final class ProfileSignedOut extends ProfileEvent {
  /// Clears the session; the router then returns to the sign-in screen.
  const ProfileSignedOut();
}
