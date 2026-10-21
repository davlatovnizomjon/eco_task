import '../../../constants/constants.dart';
import 'status_tone.dart';

/// Lifecycle of a client's service request.
enum RequestStatus {
  /// Received, no date agreed yet.
  accepted,

  /// An assignee and a date are set.
  planned,

  /// The work is being done.
  inProgress,

  /// Finished.
  done;

  /// Status parsed from its API name; unknown values fall back to [accepted].
  factory RequestStatus.fromJson(Object? name) =>
      values.firstWhere((status) => status.name == name, orElse: () => RequestStatus.accepted);

  /// Localized label.
  String get title => switch (this) {
    RequestStatus.accepted => TrWords.rsAcc.tr(),
    RequestStatus.planned => TrWords.rsPlan.tr(),
    RequestStatus.inProgress => TrWords.rsProg.tr(),
    RequestStatus.done => TrWords.rsDone.tr(),
  };

  /// Color family of the chip.
  StatusTone get tone => switch (this) {
    RequestStatus.accepted => StatusTone.neutral,
    RequestStatus.planned => StatusTone.info,
    RequestStatus.inProgress => StatusTone.warn,
    RequestStatus.done => StatusTone.primary,
  };

  /// SVG asset of the chip glyph.
  String get icon => switch (this) {
    RequestStatus.accepted => AppIcons.newIcon,
    RequestStatus.planned => AppIcons.cal,
    RequestStatus.inProgress => AppIcons.prog,
    RequestStatus.done => AppIcons.checkc,
  };

  /// True once the request left the "active" list.
  bool get isDone => this == done;
}
