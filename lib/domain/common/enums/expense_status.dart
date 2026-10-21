import '../../../constants/constants.dart';
import 'status_tone.dart';

/// Review state of an expense a worker entered against a task.
enum ExpenseStatus {
  /// Entered, waiting for the boss.
  pending,

  /// Approved (possibly for a smaller amount than entered).
  approved,

  /// Rejected by the boss.
  rejected;

  /// Status parsed from its API name; unknown values fall back to [pending].
  factory ExpenseStatus.fromJson(Object? name) =>
      values.firstWhere((status) => status.name == name, orElse: () => ExpenseStatus.pending);

  /// Localized label.
  String get title => switch (this) {
    ExpenseStatus.pending => TrWords.esPend.tr(),
    ExpenseStatus.approved => TrWords.esOk.tr(),
    ExpenseStatus.rejected => TrWords.esRej.tr(),
  };

  /// Color family of the chip.
  StatusTone get tone => switch (this) {
    ExpenseStatus.pending => StatusTone.neutral,
    ExpenseStatus.approved => StatusTone.primary,
    ExpenseStatus.rejected => StatusTone.error,
  };

  /// SVG asset of the chip glyph.
  String get icon => switch (this) {
    ExpenseStatus.pending => AppIcons.clock,
    ExpenseStatus.approved => AppIcons.check,
    ExpenseStatus.rejected => AppIcons.x,
  };
}
