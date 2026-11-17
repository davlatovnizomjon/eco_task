import '../../../constants/constants.dart';
import 'status_tone.dart';

/// Which of the four account kinds is signed in; fixes the home tabs and what
/// each screen offers. The backend returns it on `auth/login`.
enum UserRole {
  /// Company head (backend `OWNER`, shown as "Admin") — sees everything, manages accounts and finance.
  owner,

  /// Manager (backend `ASSISTANT`, shown as "Menejer") — creates, assigns and approves work; no finance or audit.
  assistant,

  /// Employee — performs the tasks assigned to them.
  worker,

  /// Customer — files service requests and follows them.
  client;

  /// Role parsed from its API name (the backend sends `OWNER`, the persisted session `owner`); unknown values
  /// fall back to [worker].
  factory UserRole.fromJson(Object? name) =>
      values.firstWhere((role) => role.name == '$name'.toLowerCase(), orElse: () => UserRole.worker);

  /// Color family of the role pill: amber admin, blue manager, green worker, gray client.
  StatusTone get tone => switch (this) {
    UserRole.owner => StatusTone.warn,
    UserRole.assistant => StatusTone.info,
    UserRole.worker => StatusTone.primary,
    UserRole.client => StatusTone.neutral,
  };

  /// Name the backend uses for this role.
  String get apiName => name.toUpperCase();

  /// Localized role name.
  String get title => switch (this) {
    UserRole.owner => TrWords.roleAdmin.tr(),
    UserRole.assistant => TrWords.roleManager.tr(),
    UserRole.worker => TrWords.roleWorker.tr(),
    UserRole.client => TrWords.roleClient.tr(),
  };

  /// True for the two roles that create, review and approve work.
  bool get isBoss => this == owner || this == assistant;
}
