/// Where one person stands in a call.
enum CallPartyState {
  /// Invited and still ringing.
  invited,

  /// In the call.
  joined,

  /// Said no to the invitation.
  declined,

  /// Did not answer in time.
  missed,

  /// Was in the call and left.
  left;

  /// State parsed from its API name (`INVITED`); unknown values fall back to [left].
  factory CallPartyState.fromJson(Object? name) =>
      values.firstWhere((state) => state.name == '$name'.toLowerCase(), orElse: () => CallPartyState.left);
}
