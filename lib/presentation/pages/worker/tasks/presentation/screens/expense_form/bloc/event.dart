part of 'bloc.dart';

/// Base of every action the expense form can dispatch.
sealed class ExpenseFormEvent {
  /// Allows the events to have const constructors.
  const ExpenseFormEvent();
}

/// The user typed in the amount field.
final class ExpenseFormAmountChanged extends ExpenseFormEvent {
  /// Raw (thousands-formatted) field text.
  final String value;

  /// Carries the new amount text.
  const ExpenseFormAmountChanged(this.value);
}

/// The user picked an expense type.
final class ExpenseFormKindChanged extends ExpenseFormEvent {
  /// The chosen type.
  final ExpenseKind value;

  /// Carries the chosen type.
  const ExpenseFormKindChanged(this.value);
}

/// The user typed in the note field.
final class ExpenseFormNoteChanged extends ExpenseFormEvent {
  /// Raw field text.
  final String value;

  /// Carries the new note.
  const ExpenseFormNoteChanged(this.value);
}

/// The user attached or removed the receipt photo.
final class ExpenseFormReceiptToggled extends ExpenseFormEvent {
  /// Flips the receipt flag.
  const ExpenseFormReceiptToggled();
}

/// The user pressed "send for review".
final class ExpenseFormSubmitted extends ExpenseFormEvent {
  /// Triggers validation and, if it passes, the request.
  const ExpenseFormSubmitted();
}
