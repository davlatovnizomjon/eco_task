import 'user_ref.dart';

/// One person assigned to a task, with their quota and progress.
class TaskAssignee {
  /// The assigned person.
  final UserRef user;

  /// Quota in pieces; 0 for tasks that are simply done or not done.
  final int share;

  /// Pieces completed so far.
  final int done;

  /// Builds an assignee from its parts.
  const TaskAssignee({required this.user, this.share = 0, this.done = 0});

  /// Parses the API object.
  factory TaskAssignee.fromJson(Map<String, dynamic> json) => TaskAssignee(
    user: UserRef.fromJson(json['user'] as Map<String, dynamic>),
    share: (json['share'] as num?)?.toInt() ?? 0,
    done: (json['done'] as num?)?.toInt() ?? 0,
  );

  /// Serializes the assignee.
  Map<String, dynamic> toJson() => {'user': user.toJson(), 'share': share, 'done': done};

  /// Id of the assigned person.
  String get userId => user.id;

  /// Copy with a new [done] counter.
  TaskAssignee withDone(int value) => TaskAssignee(user: user, share: share, done: value);
}
