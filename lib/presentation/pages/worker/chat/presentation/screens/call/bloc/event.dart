part of 'bloc.dart';

/// Base of every action the call screen can dispatch.
sealed class CallEvent {
  /// Allows the events to have const constructors.
  const CallEvent();
}

/// The screen opened: loads the call (or starts a new one) and joins it when the person is already in.
final class CallStarted extends CallEvent {
  /// Fires the load.
  const CallStarted();
}

/// The green button of an incoming call was pressed.
final class CallAnswered extends CallEvent {
  /// Joins the ringing call.
  const CallAnswered();
}

/// The red button of an incoming call was pressed.
final class CallDeclined extends CallEvent {
  /// Refuses the ringing call.
  const CallDeclined();
}

/// Hang up / leave / cancel was pressed.
final class CallEnded extends CallEvent {
  /// Leaves the call (cancels it while it still rings).
  const CallEnded();
}

/// The "swipe to call again" control was used on a finished call.
final class CallRedialed extends CallEvent {
  /// Starts a fresh call in the same conversation with the same media.
  const CallRedialed();
}

/// The microphone button was pressed.
final class CallMuteToggled extends CallEvent {
  /// Flips the microphone.
  const CallMuteToggled();
}

/// The loudspeaker button was pressed.
final class CallSpeakerToggled extends CallEvent {
  /// Flips the loudspeaker.
  const CallSpeakerToggled();
}

/// The camera button was pressed.
final class CallVideoToggled extends CallEvent {
  /// Flips the camera.
  const CallVideoToggled();
}

/// The "flip camera" button (or a camera choice) was used.
final class CallCameraFlipped extends CallEvent {
  /// Switches between the front and back camera.
  const CallCameraFlipped();
}

/// People were picked in the "add to call" sheet.
final class CallInvited extends CallEvent {
  /// Account ids of the people to ring.
  final List<String> userIds;

  /// Carries the picked people.
  const CallInvited(this.userIds);
}

/// The participant grid moved to another page.
final class CallPageChanged extends CallEvent {
  /// Zero-based page.
  final int page;

  /// Carries the page.
  const CallPageChanged(this.page);
}

/// The short notice line ("X declined") timed out.
final class CallNoticeCleared extends CallEvent {
  /// Hides the notice.
  const CallNoticeCleared();
}

/// The server pushed a change of this call.
final class _CallPushed extends CallEvent {
  /// The call as it is now.
  final CallModel call;

  /// Carries the call.
  const _CallPushed(this.call);
}

/// One second of the call timer passed.
final class _CallTicked extends CallEvent {
  /// Advances the timer.
  const _CallTicked();
}
