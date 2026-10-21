import '../../../constants/constants.dart';
import 'status_tone.dart';

/// How important a task is; drives the marker on cards and the sort order.
enum TaskPriority {
  /// Must be done first.
  high,

  /// Normal importance.
  medium,

  /// Can wait.
  low;

  /// Priority parsed from its API name; unknown values fall back to [medium].
  factory TaskPriority.fromJson(Object? name) =>
      values.firstWhere((priority) => priority.name == name, orElse: () => TaskPriority.medium);

  /// Localized label.
  String get title => switch (this) {
    TaskPriority.high => TrWords.priHi.tr(),
    TaskPriority.medium => TrWords.priMd.tr(),
    TaskPriority.low => TrWords.priLo.tr(),
  };

  /// Color family of the marker.
  StatusTone get tone => switch (this) {
    TaskPriority.high => StatusTone.error,
    TaskPriority.medium => StatusTone.warn,
    TaskPriority.low => StatusTone.neutral,
  };

  /// SVG asset of the marker glyph.
  String get icon => switch (this) {
    TaskPriority.high => AppIcons.up,
    TaskPriority.medium => AppIcons.eq,
    TaskPriority.low => AppIcons.lo,
  };
}
