/// Lifecycle of a call as the backend reports it.
enum CallStatus {
  /// Invitations are out, nobody has answered yet.
  ringing,

  /// Somebody answered; people are talking.
  active,

  /// Finished normally.
  ended,

  /// Every invitee said no.
  declined,

  /// The caller hung up before anybody answered.
  canceled,

  /// Nobody answered in time.
  missed;

  /// Status parsed from its API name (`RINGING`); unknown values fall back to [ended].
  factory CallStatus.fromJson(Object? name) =>
      values.firstWhere((status) => status.name == '$name'.toLowerCase(), orElse: () => CallStatus.ended);

  /// True while the call can still be answered or talked in.
  bool get isLive => this == ringing || this == active;
}
