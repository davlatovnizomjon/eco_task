import '../../../constants/constants.dart';
import 'status_tone.dart';

/// Lifecycle of a task. "Overdue" is not a value: it is derived from the due
/// date of an open task.
enum TaskStatus {
  /// Created, nobody started it yet.
  fresh,

  /// A worker started it and reports progress.
  prog,

  /// Result submitted, waiting for the boss's decision.
  rev,

  /// Result approved.
  done,

  /// Worker reported it cannot be done.
  fail,

  /// Canceled by the boss.
  canc;

  /// Status parsed from its API name; unknown values fall back to [fresh].
  factory TaskStatus.fromJson(Object? name) =>
      values.firstWhere((status) => status.name == name, orElse: () => TaskStatus.fresh);

  /// Localized label.
  String get title => switch (this) {
    TaskStatus.fresh => TrWords.stNew.tr(),
    TaskStatus.prog => TrWords.stProg.tr(),
    TaskStatus.rev => TrWords.stRev.tr(),
    TaskStatus.done => TrWords.stDone.tr(),
    TaskStatus.fail => TrWords.stFail.tr(),
    TaskStatus.canc => TrWords.stCanc.tr(),
  };

  /// Color family of the status chip.
  StatusTone get tone => switch (this) {
    TaskStatus.fresh => StatusTone.neutral,
    TaskStatus.prog => StatusTone.info,
    TaskStatus.rev => StatusTone.review,
    TaskStatus.done => StatusTone.primary,
    TaskStatus.fail => StatusTone.error,
    TaskStatus.canc => StatusTone.neutral,
  };

  /// SVG asset of the status glyph.
  String get icon => switch (this) {
    TaskStatus.fresh => AppIcons.newIcon,
    TaskStatus.prog => AppIcons.prog,
    TaskStatus.rev => AppIcons.eye,
    TaskStatus.done => AppIcons.checkc,
    TaskStatus.fail => AppIcons.xc,
    TaskStatus.canc => AppIcons.ban,
  };

  /// True while the task is still being worked on (it can become overdue).
  bool get isOpen => this == fresh || this == prog;

  /// True once the task left the active lists (done, failed or canceled).
  bool get isClosed => this == done || this == fail || this == canc;
}
