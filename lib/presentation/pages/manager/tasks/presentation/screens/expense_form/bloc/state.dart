part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the expense form renders itself from.
class ExpenseFormState extends Equatable {
  /// Request lifecycle of the save.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// Raw amount text (thousands-formatted).
  final String amount;

  /// Chosen expense type.
  final ExpenseKind kind;

  /// Raw note text.
  final String note;

  /// True when a receipt photo is attached.
  final bool hasReceipt;

  /// Flipped on the first submit attempt; until then no field turns red.
  final bool showErrors;

  /// One-shot: the expense was saved and the screen should close.
  final bool saved;

  /// Builds the initial, empty form.
  const ExpenseFormState({
    this.status = ScreenStatus.initial,
    this.response,
    this.amount = '',
    this.kind = ExpenseKind.transport,
    this.note = '',
    this.hasReceipt = false,
    this.showErrors = false,
    this.saved = false,
  });

  /// Validation message for the amount, independent of [showErrors].
  String? get amountError => MoneyFormatter.parse(amount) > 0 ? null : TrWords.vAmountRequired.tr();

  /// Amount error the FIELD should display — nothing before the first submit.
  String? get visibleAmountError => showErrors ? amountError : null;

  /// Copies the state; [response] and [saved] reset unless passed, so each
  /// fires once per emit.
  ExpenseFormState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    String? amount,
    ExpenseKind? kind,
    String? note,
    bool? hasReceipt,
    bool? showErrors,
    bool saved = false,
  }) => ExpenseFormState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    amount: amount ?? this.amount,
    kind: kind ?? this.kind,
    note: note ?? this.note,
    hasReceipt: hasReceipt ?? this.hasReceipt,
    showErrors: showErrors ?? this.showErrors,
    saved: saved,
  );

  @override
  List<Object?> get props => [status, response, amount, kind, note, hasReceipt, showErrors, saved];
}
