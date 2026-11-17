import '../../../constants/constants.dart';

/// The six statistics screens of the admin "report" tab.
enum StatsKind {
  /// Revenue, plan against result and payment states.
  finance,

  /// Task counts by status, completion per day/week and timeliness.
  tasks,

  /// The signed-in admin's own results.
  mine,

  /// New clients and the client list.
  clients,

  /// Head count and the most active employees.
  staff,

  /// Managers and what each of them brought in.
  managers;

  /// Kind parsed from its route segment; unknown values fall back to [tasks].
  factory StatsKind.fromName(String? name) =>
      values.firstWhere((kind) => kind.name == name, orElse: () => StatsKind.tasks);

  /// Screen title and card title on the report tab.
  String get title => switch (this) {
    StatsKind.finance => TrWords.sxFin.tr(),
    StatsKind.tasks => TrWords.sxTasks.tr(),
    StatsKind.mine => TrWords.sxMine.tr(),
    StatsKind.clients => TrWords.sxClients.tr(),
    StatsKind.staff => TrWords.sxStaff.tr(),
    StatsKind.managers => TrWords.sxMgr.tr(),
  };

  /// Hint under the card title on the report tab.
  String get subtitle => switch (this) {
    StatsKind.finance => TrWords.sxFinD.tr(),
    StatsKind.tasks => TrWords.sxTasksD.tr(),
    StatsKind.mine => TrWords.sxMineD.tr(),
    StatsKind.clients => TrWords.sxClientsD.tr(),
    StatsKind.staff || StatsKind.managers => TrWords.sxListD.tr(),
  };

  /// Glyph of the card tile and of the empty state.
  String get icon => switch (this) {
    StatsKind.finance => AppIcons.coins,
    StatsKind.tasks => AppIcons.tasks,
    StatsKind.mine => AppIcons.chart,
    StatsKind.clients => AppIcons.users,
    StatsKind.staff => AppIcons.user,
    StatsKind.managers => AppIcons.shield,
  };

  /// Caption of the headline number.
  String get headline => switch (this) {
    StatsKind.finance => TrWords.sxIncome.tr(),
    StatsKind.tasks => TrWords.sxTotalTasks.tr(),
    StatsKind.mine => TrWords.sxMyCreated.tr(),
    StatsKind.clients => TrWords.sxNewClients.tr(),
    StatsKind.staff => TrWords.sxAllStaff.tr(),
    StatsKind.managers => TrWords.sxAllMgr.tr(),
  };

  /// Title of the empty state.
  String get emptyTitle => switch (this) {
    StatsKind.finance => TrWords.sxEFinT.tr(),
    StatsKind.tasks => TrWords.sxETasksT.tr(),
    StatsKind.mine => TrWords.sxEMineT.tr(),
    StatsKind.clients => TrWords.sxEClientsT.tr(),
    StatsKind.staff => TrWords.sxEStaffT.tr(),
    StatsKind.managers => TrWords.sxEMgrT.tr(),
  };

  /// Hint of the empty state.
  String get emptyHint => switch (this) {
    StatsKind.finance => TrWords.sxEFinD.tr(),
    StatsKind.tasks => TrWords.sxETasksD.tr(),
    StatsKind.mine => TrWords.sxEMineD.tr(),
    StatsKind.clients => TrWords.sxEClientsD.tr(),
    StatsKind.staff => TrWords.sxEStaffD.tr(),
    StatsKind.managers => TrWords.sxEMgrD.tr(),
  };
}
