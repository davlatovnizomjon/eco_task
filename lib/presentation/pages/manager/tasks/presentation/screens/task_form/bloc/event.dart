part of 'bloc.dart';

/// Base of every action the task form can dispatch.
sealed class TaskFormEvent {
  /// Allows the events to have const constructors.
  const TaskFormEvent();
}

/// The form opened — load assignable people (and the task when editing).
final class TaskFormStarted extends TaskFormEvent {
  /// Fires the initial loads.
  const TaskFormStarted();
}

/// The user typed in the title field.
final class TaskFormTitleChanged extends TaskFormEvent {
  /// Raw field text.
  final String value;

  /// Carries the new title.
  const TaskFormTitleChanged(this.value);
}

/// The assignee picker closed with a new selection.
final class TaskFormAssigneesChanged extends TaskFormEvent {
  /// Everyone now assigned, in display order.
  final List<UserRef> people;

  /// Carries the new selection.
  const TaskFormAssigneesChanged(this.people);
}

/// The "separate quota for each assignee" switch was toggled.
final class TaskFormSplitToggled extends TaskFormEvent {
  /// New switch value.
  final bool value;

  /// Carries the switch value.
  const TaskFormSplitToggled(this.value);
}

/// The user typed a quota for one assignee.
final class TaskFormShareChanged extends TaskFormEvent {
  /// Id of the assignee.
  final String userId;

  /// Raw quota text.
  final String value;

  /// Carries the quota of one assignee.
  const TaskFormShareChanged(this.userId, this.value);
}

/// A deadline was picked.
final class TaskFormDueChanged extends TaskFormEvent {
  /// The chosen moment.
  final DateTime value;

  /// Carries the new deadline.
  const TaskFormDueChanged(this.value);
}

/// A priority was picked.
final class TaskFormPriorityChanged extends TaskFormEvent {
  /// The chosen priority.
  final TaskPriority value;

  /// Carries the new priority.
  const TaskFormPriorityChanged(this.value);
}

/// The user typed in the reward field.
final class TaskFormRewardChanged extends TaskFormEvent {
  /// Raw (thousands-formatted) field text.
  final String value;

  /// Carries the new reward text.
  const TaskFormRewardChanged(this.value);
}

/// The user typed in the description field.
final class TaskFormDescriptionChanged extends TaskFormEvent {
  /// Raw field text.
  final String value;

  /// Carries the new description.
  const TaskFormDescriptionChanged(this.value);
}

/// The user typed in the expected-result field.
final class TaskFormExpectedChanged extends TaskFormEvent {
  /// Raw field text.
  final String value;

  /// Carries the new expected result.
  const TaskFormExpectedChanged(this.value);
}

/// The user pressed create/save.
final class TaskFormSubmitted extends TaskFormEvent {
  /// Triggers validation and, if it passes, the save request.
  const TaskFormSubmitted();
}

/// "Next" or a step jump of the wizard.
final class TaskFormStepChanged extends TaskFormEvent {
  /// Step to show, 0..4; moving forward is refused while the current step is invalid.
  final int step;

  /// Carries the target step.
  const TaskFormStepChanged(this.step);
}

/// The client type or name changed.
final class TaskFormClientChanged extends TaskFormEvent {
  /// True when the client is an organization.
  final bool isOrg;

  /// Organization or client name.
  final String name;

  /// Carries the client.
  const TaskFormClientChanged({required this.isOrg, required this.name});
}

/// The address changed.
final class TaskFormAddressChanged extends TaskFormEvent {
  /// New address text.
  final String value;

  /// Carries the address.
  const TaskFormAddressChanged(this.value);
}

/// The price currency changed.
final class TaskFormCurrencyChanged extends TaskFormEvent {
  /// `uzs` or `usd`.
  final String value;

  /// Carries the currency.
  const TaskFormCurrencyChanged(this.value);
}

/// A photo or document was picked and must be uploaded.
final class TaskFormFilePicked extends TaskFormEvent {
  /// The picked file.
  final PickedFile file;

  /// Carries the file.
  const TaskFormFilePicked(this.file);
}

/// A thumbnail's "x" was tapped.
final class TaskFormFileRemoved extends TaskFormEvent {
  /// Id of the file taken off the task.
  final int id;

  /// Carries the id.
  const TaskFormFileRemoved(this.id);
}
