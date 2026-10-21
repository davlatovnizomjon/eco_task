import '../../../constants/constants.dart';

/// Time window of the reports and status screens.
enum ReportPeriod {
  /// Last seven days.
  week,

  /// Current month.
  month,

  /// Current quarter.
  quarter;

  /// Localized tab label.
  String get title => switch (this) {
    ReportPeriod.week => TrWords.repWeek.tr(),
    ReportPeriod.month => TrWords.repMonth.tr(),
    ReportPeriod.quarter => TrWords.repQuarter.tr(),
  };
}
