part of 'bloc.dart';

/// Base of every action the group-edit page can dispatch.
sealed class GroupEditEvent {
  /// Allows the events to have const constructors.
  const GroupEditEvent();
}

/// The page opened, or "retry" was tapped.
final class GroupEditStarted extends GroupEditEvent {
  /// Fires the load.
  const GroupEditStarted();
}

/// The title field changed.
final class GroupEditTitleChanged extends GroupEditEvent {
  /// New title text.
  final String title;

  /// Carries the text.
  const GroupEditTitleChanged(this.title);
}

/// A member's minus button was tapped.
final class GroupEditMemberRemoved extends GroupEditEvent {
  /// Id of the member taken out of the draft.
  final String id;

  /// Carries the id.
  const GroupEditMemberRemoved(this.id);
}

/// People were picked in the member sheet.
final class GroupEditMembersAdded extends GroupEditEvent {
  /// The people added to the draft.
  final List<UserRef> people;

  /// Carries the people.
  const GroupEditMembersAdded(this.people);
}

/// "Save" was tapped.
final class GroupEditSaved extends GroupEditEvent {
  /// Applies the draft.
  const GroupEditSaved();
}

/// A group photo was picked; upload it and keep it for the save.
final class GroupEditPhotoPicked extends GroupEditEvent {
  /// The picked photo.
  final PickedFile file;

  /// Carries the photo.
  const GroupEditPhotoPicked(this.file);
}
