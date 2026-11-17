import '../../../constants/constants.dart';

/// Deadline window filter of the task list.
enum TaskDueFilter {
  /// No deadline restriction.
  any,

  /// Due today.
  today,

  /// Due within the next seven days.
  week,

  /// Due within the current calendar month.
  month,

  /// Due inside a hand-picked date range (`TaskQuery.from` … `TaskQuery.to`).
  range;

  /// Localized chip label (empty for [any]).
  String get title => switch (this) {
    TaskDueFilter.any => TrWords.cAll.tr(),
    TaskDueFilter.today => TrWords.cToday.tr(),
    TaskDueFilter.week => TrWords.tasksThisWeek.tr(),
    TaskDueFilter.month => TrWords.fltMonth.tr(),
    TaskDueFilter.range => TrWords.fltPickDate.tr(),
  };
}
