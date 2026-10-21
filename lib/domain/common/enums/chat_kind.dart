/// What a conversation is attached to; fixes who may be in it and how it is titled.
enum ChatKind {
  /// Two people.
  direct,

  /// A named group created by a boss.
  group,

  /// The discussion of one task; its participants are the task's visible people.
  task;

  /// Kind parsed from its API name (`DIRECT`); unknown values fall back to [direct].
  factory ChatKind.fromJson(Object? name) =>
      values.firstWhere((kind) => kind.name == '$name'.toLowerCase(), orElse: () => ChatKind.direct);

  /// Name the backend uses for this kind.
  String get apiName => name.toUpperCase();
}
