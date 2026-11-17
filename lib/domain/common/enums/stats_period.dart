import '../../../constants/constants.dart';

/// Length of the window a statistics screen covers.
enum StatsPeriod {
  /// Monday to Sunday.
  week,

  /// A calendar month.
  month,

  /// A calendar year.
  year;

  /// Label of the period switch.
  String get title => switch (this) {
    StatsPeriod.week => TrWords.sxWeek.tr(),
    StatsPeriod.month => TrWords.sxMonth.tr(),
    StatsPeriod.year => TrWords.sxYear.tr(),
  };

  /// Caption under the headline number: what the change is compared with.
  String get versus => switch (this) {
    StatsPeriod.week => TrWords.sxVsWeek.tr(),
    StatsPeriod.month => TrWords.sxVsMonth.tr(),
    StatsPeriod.year => TrWords.sxVsYear.tr(),
  };

  /// First day of the window that lies [offset] periods from the current one (0 = current, -1 = previous).
  DateTime start(int offset) {
    /// Today, the anchor of offset 0.
    final now = DateTime.now();
    return switch (this) {
      StatsPeriod.week => DateTime(now.year, now.month, now.day - (now.weekday - 1) + offset * 7),
      StatsPeriod.month => DateTime(now.year, now.month + offset),
      StatsPeriod.year => DateTime(now.year + offset),
    };
  }
}
