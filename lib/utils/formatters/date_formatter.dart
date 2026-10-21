import '../../constants/constants.dart';

/// Renders dates and times the way the UI copy is written — `9-oktabr`,
/// `Bugun, 16:00`, `15 daqiqa oldin` — in the active app language.
///
/// Every date shown to the user goes through here; an ISO string from the API
/// is never printed directly.
class DateFormatter {
  /// Private constructor — the class is a namespace of statics.
  const DateFormatter._();

  /// Month name keys, indexed by `DateTime.month - 1`.
  static const _months = [
    TrWords.m1,
    TrWords.m2,
    TrWords.m3,
    TrWords.m4,
    TrWords.m5,
    TrWords.m6,
    TrWords.m7,
    TrWords.m8,
    TrWords.m9,
    TrWords.m10,
    TrWords.m11,
    TrWords.m12,
  ];

  /// Short weekday keys, indexed by `DateTime.weekday - 1` (Monday first).
  static const _weekdays = [TrWords.wd1, TrWords.wd2, TrWords.wd3, TrWords.wd4, TrWords.wd5, TrWords.wd6, TrWords.wd7];

  /// Long weekday keys, indexed by `DateTime.weekday - 1` (Monday first).
  static const _weekdaysLong = [
    TrWords.wdl1,
    TrWords.wdl2,
    TrWords.wdl3,
    TrWords.wdl4,
    TrWords.wdl5,
    TrWords.wdl6,
    TrWords.wdl7,
  ];

  /// True while the active language is Russian (day and month are space-separated).
  static bool get _isRussian => (Intl.defaultLocale ?? '').startsWith('ru');

  /// `9-oktabr` (Uzbek) or `9 октября` (Russian).
  static String day(DateTime date) => '${date.day}${_isRussian ? ' ' : '-'}${_months[date.month - 1].tr()}';

  /// `18:00`.
  static String time(DateTime date) => DateFormat('HH:mm').format(date);

  /// `9-oktabr, 18:00`.
  static String dayTime(DateTime date) => '${day(date)}, ${time(date)}';

  /// `Du` — short weekday name.
  static String weekdayShort(DateTime date) => _weekdays[date.weekday - 1].tr();

  /// `Juma, 9-oktabr`.
  static String weekdayDay(DateTime date) => '${_weekdaysLong[date.weekday - 1].tr()}, ${day(date)}';

  /// `Oktabr 2026` — month and year header.
  static String monthYear(DateTime date) => '${_months[date.month - 1].tr()} ${date.year}';

  /// Same calendar day, ignoring time.
  static bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Whole calendar days from today to [date] (negative when in the past).
  static int daysTo(DateTime date) {
    final now = DateTime.now();
    return DateTime(date.year, date.month, date.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  /// `Bugun, 16:00`, `Ertaga, 11:00` or `12-oktabr, 18:00`; the time is dropped
  /// when [withTime] is false.
  static String due(DateTime date, {bool withTime = true}) {
    final diff = daysTo(date);
    final label = diff == 0
        ? TrWords.cToday.tr()
        : diff == 1
        ? TrWords.cTomorrow.tr()
        : day(date);
    return withTime ? '$label, ${time(date)}' : label;
  }

  /// `hozir`, `15 daqiqa oldin`, `09:00` (today), `Kecha, 17:05` or `8-oktabr, 17:05`.
  static String ago(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return TrWords.cNow.tr();
    if (diff.inMinutes < 60) return TrWords.cMinAgo.tr(args: ['${diff.inMinutes}']);
    if (daysTo(date) == 0) return time(date);
    return '${daysTo(date) == -1 ? TrWords.cYesterday.tr() : day(date)}, ${time(date)}';
  }
}
