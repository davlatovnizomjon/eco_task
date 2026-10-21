import '../../../constants/constants.dart';
import 'status_tone.dart';
import 'task_status.dart';

/// Filter tabs of the notifications screen.
enum NotificationGroup {
  /// Everything.
  all,

  /// Only unread entries.
  unread,

  /// Results waiting for review.
  review,

  /// Deadline reminders.
  deadlines,

  /// Expense news.
  expenses,
}

/// Type of an inbox entry; picks its icon, color, texts and filter group.
enum NotificationKind {
  /// A worker submitted a result.
  review,

  /// A worker entered an expense.
  expense,

  /// A task passed its deadline.
  overdue,

  /// Someone commented on a task.
  comment,

  /// A client filed a request.
  request,

  /// A task changed status.
  status,

  /// A task was assigned to you.
  newTask,

  /// A deadline is close.
  dueSoon,

  /// Your result was approved.
  approved,

  /// Your expense was approved.
  expenseApproved,

  /// Your result was returned for rework.
  returned,

  /// Your request was planned.
  requestPlanned,

  /// A message arrived on your request.
  requestMessage,

  /// Your request was accepted.
  requestAccepted,

  /// Your request is finished.
  requestDone,

  /// A task was assigned to you (live backend).
  taskAssigned,

  /// A task you follow changed status (live backend).
  taskStatus,

  /// A new chat message arrived.
  chatMessage;

  /// Kind parsed from its API name; unknown values fall back to [status].
  factory NotificationKind.fromJson(Object? name) =>
      values.firstWhere((kind) => kind.name == name, orElse: () => NotificationKind.status);

  /// Localized headline filled with [args].
  String title(List<String> args) => switch (this) {
    NotificationKind.review => TrWords.ntfReviewT.tr(args: args),
    NotificationKind.expense => TrWords.ntfExpenseT.tr(args: args),
    NotificationKind.overdue => TrWords.ntfOverdueT.tr(args: args),
    NotificationKind.comment => TrWords.ntfCommentT.tr(args: args),
    NotificationKind.request => TrWords.ntfRequestT.tr(args: args),
    NotificationKind.status => TrWords.ntfStatusT.tr(args: args),
    NotificationKind.newTask => TrWords.ntfNewtaskT.tr(args: args),
    NotificationKind.dueSoon => TrWords.ntfDuesoonT.tr(args: args),
    NotificationKind.approved => TrWords.ntfApprovedT.tr(args: args),
    NotificationKind.expenseApproved => TrWords.ntfExpokT.tr(args: args),
    NotificationKind.returned => TrWords.ntfReturnedT.tr(args: args),
    NotificationKind.requestPlanned => TrWords.ntfRplanT.tr(args: args),
    NotificationKind.requestMessage => TrWords.ntfRmsgT.tr(args: args),
    NotificationKind.requestAccepted => TrWords.ntfRaccT.tr(args: args),
    NotificationKind.requestDone => TrWords.ntfRdoneT.tr(args: args),
    NotificationKind.taskAssigned => TrWords.ntfTaskAssignedT.tr(),
    NotificationKind.taskStatus => TrWords.ntfTaskStatusT.tr(),
    NotificationKind.chatMessage => TrWords.ntfChatMessageT.tr(args: args.take(1).toList()),
  };

  /// Localized body filled with [args].
  String body(List<String> args) => switch (this) {
    NotificationKind.review => TrWords.ntfReviewB.tr(args: args),
    NotificationKind.expense => TrWords.ntfExpenseB.tr(args: args),
    NotificationKind.overdue => TrWords.ntfOverdueB.tr(args: args),
    NotificationKind.comment => TrWords.ntfCommentB.tr(args: args),
    NotificationKind.request => TrWords.ntfRequestB.tr(args: args),
    NotificationKind.status => TrWords.ntfStatusB.tr(args: args),
    NotificationKind.newTask => TrWords.ntfNewtaskB.tr(args: args),
    NotificationKind.dueSoon => TrWords.ntfDuesoonB.tr(args: args),
    NotificationKind.approved => TrWords.ntfApprovedB.tr(args: args),
    NotificationKind.expenseApproved => TrWords.ntfExpokB.tr(args: args),
    NotificationKind.returned => TrWords.ntfReturnedB.tr(args: args),
    NotificationKind.requestPlanned => TrWords.ntfRplanB.tr(args: args),
    NotificationKind.requestMessage => TrWords.ntfRmsgB.tr(args: args),
    NotificationKind.requestAccepted => TrWords.ntfRaccB.tr(args: args),
    NotificationKind.requestDone => TrWords.ntfRdoneB.tr(args: args),
    NotificationKind.taskAssigned => TrWords.ntfTaskAssignedB.tr(args: args.take(1).toList()),
    // `args` = [task title, TaskStatus name]; the status is localized here so the stored text never goes stale.
    NotificationKind.taskStatus => TrWords.ntfTaskStatusB.tr(
      args: [args.isEmpty ? '' : args[0], args.length < 2 ? '' : TaskStatus.fromJson(args[1]).title],
    ),
    NotificationKind.chatMessage => TrWords.ntfChatMessageB.tr(),
  };

  /// SVG asset of the entry's tile.
  String get icon => switch (this) {
    NotificationKind.review => AppIcons.eye,
    NotificationKind.expense || NotificationKind.expenseApproved => AppIcons.receipt,
    NotificationKind.overdue || NotificationKind.dueSoon => AppIcons.alarm,
    NotificationKind.comment || NotificationKind.requestMessage || NotificationKind.chatMessage => AppIcons.msg,
    NotificationKind.request => AppIcons.file,
    NotificationKind.status ||
    NotificationKind.taskStatus ||
    NotificationKind.approved ||
    NotificationKind.requestAccepted => AppIcons.checkc,
    NotificationKind.newTask || NotificationKind.taskAssigned => AppIcons.tasks,
    NotificationKind.returned => AppIcons.refresh,
    NotificationKind.requestPlanned => AppIcons.cal,
    NotificationKind.requestDone => AppIcons.truck,
  };

  /// Color family of the entry's tile.
  StatusTone get tone => switch (this) {
    NotificationKind.review => StatusTone.review,
    NotificationKind.expense ||
    NotificationKind.newTask ||
    NotificationKind.taskAssigned ||
    NotificationKind.requestPlanned => StatusTone.info,
    NotificationKind.overdue || NotificationKind.dueSoon => StatusTone.warn,
    NotificationKind.comment || NotificationKind.requestMessage || NotificationKind.chatMessage => StatusTone.neutral,
    NotificationKind.returned => StatusTone.error,
    _ => StatusTone.primary,
  };

  /// Filter tab this entry belongs to (besides "all" and "unread").
  NotificationGroup get group => switch (this) {
    NotificationKind.review => NotificationGroup.review,
    NotificationKind.overdue || NotificationKind.dueSoon => NotificationGroup.deadlines,
    NotificationKind.expense || NotificationKind.expenseApproved => NotificationGroup.expenses,
    _ => NotificationGroup.all,
  };
}
