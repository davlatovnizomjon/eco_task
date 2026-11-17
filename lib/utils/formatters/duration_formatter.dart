/// Formats lengths of time for the call screens.
abstract final class DurationFormatter {
  /// `mm:ss`, or `h:mm:ss` from one hour on, e.g. `02:14`.
  static String clock(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }
}
