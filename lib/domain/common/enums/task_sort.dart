import '../../../constants/constants.dart';

/// Sort order of the task list.
enum TaskSort {
  /// Soonest deadline first.
  due,

  /// Most important first.
  priority,

  /// Newest task first.
  created;

  /// The next order in the cycle, used by the compact sort button.
  TaskSort get next => values[(index + 1) % values.length];

  /// Localized full option label.
  String get title => switch (this) {
    TaskSort.due => TrWords.tasksSortDueFull.tr(),
    TaskSort.priority => TrWords.tasksSortPri.tr(),
    TaskSort.created => TrWords.tasksSortNew.tr(),
  };

  /// Localized short label for the compact sort button.
  String get shortTitle => switch (this) {
    TaskSort.due => TrWords.tasksSortDue.tr(),
    TaskSort.priority => TrWords.tasksSortPri.tr(),
    TaskSort.created => TrWords.tasksSortNew.tr(),
  };
}
