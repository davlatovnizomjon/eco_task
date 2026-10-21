/// Numbers shown on the profile screen, depending on the role.
class ProfileSummary {
  /// Open tasks of the user (or of the whole scope for a boss).
  final int activeTasks;

  /// Completed tasks of the user.
  final int doneTasks;

  /// Reward the boss approved for the user this month.
  final int monthReward;

  /// Part of [monthReward] already paid out.
  final int paidReward;

  /// Expenses waiting for a decision (boss only).
  final int pendingExpenses;

  /// Staff in the boss's scope (boss only).
  final int teamSize;

  /// Builds the summary from its parts.
  const ProfileSummary({
    this.activeTasks = 0,
    this.doneTasks = 0,
    this.monthReward = 0,
    this.paidReward = 0,
    this.pendingExpenses = 0,
    this.teamSize = 0,
  });

  /// Parses the API object.
  factory ProfileSummary.fromJson(Map<String, dynamic> json) => ProfileSummary(
    activeTasks: (json['activeTasks'] as num?)?.toInt() ?? 0,
    doneTasks: (json['doneTasks'] as num?)?.toInt() ?? 0,
    monthReward: (json['monthReward'] as num?)?.toInt() ?? 0,
    paidReward: (json['paidReward'] as num?)?.toInt() ?? 0,
    pendingExpenses: (json['pendingExpenses'] as num?)?.toInt() ?? 0,
    teamSize: (json['teamSize'] as num?)?.toInt() ?? 0,
  );
}
