import '../../../constants/constants.dart';

/// One kind of entry in a task's activity log.
enum LogKind {
  /// Task created.
  created,

  /// First progress update moved it to "in progress".
  started,

  /// Progress counter changed.
  progress,

  /// An expense was added.
  expense,

  /// An expense was approved.
  expenseApproved,

  /// Result submitted for review.
  submitted,

  /// Result approved.
  done,

  /// Returned for rework.
  returned,

  /// Canceled.
  canceled,

  /// Marked as impossible to do.
  failed;

  /// Kind parsed from its API name; unknown values fall back to [created].
  factory LogKind.fromJson(Object? name) =>
      values.firstWhere((kind) => kind.name == name, orElse: () => LogKind.created);

  /// Localized sentence; [args] fill its `{}` placeholders.
  String text(List<String> args) => switch (this) {
    LogKind.created => TrWords.tasksLogCreated.tr(),
    LogKind.started => TrWords.tasksLogStarted.tr(),
    LogKind.progress => TrWords.tasksLogProgress.tr(args: args),
    LogKind.expense => TrWords.tasksLogExpense.tr(args: args),
    LogKind.expenseApproved => TrWords.tasksLogExpOk.tr(args: args),
    LogKind.submitted => TrWords.tasksLogSubmitted.tr(),
    LogKind.done => TrWords.tasksLogDone.tr(),
    LogKind.returned => TrWords.tasksLogReturned.tr(),
    LogKind.canceled => TrWords.tasksLogCancel.tr(),
    LogKind.failed => TrWords.tasksLogFailed.tr(),
  };

  /// SVG asset of the timeline dot.
  String get icon => switch (this) {
    LogKind.created => AppIcons.plus,
    LogKind.started => AppIcons.play,
    LogKind.progress => AppIcons.prog,
    LogKind.expense || LogKind.expenseApproved => AppIcons.receipt,
    LogKind.submitted => AppIcons.send,
    LogKind.done => AppIcons.check,
    LogKind.returned => AppIcons.refresh,
    LogKind.canceled => AppIcons.ban,
    LogKind.failed => AppIcons.xc,
  };
}
