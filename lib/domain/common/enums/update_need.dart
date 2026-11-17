/// How strongly the installed build must be replaced, decided by comparing its version with the backend's release.
enum UpdateNeed {
  /// The installed build is current (or the platform has no store to update from).
  none,

  /// A newer build exists; the user may postpone it.
  optional,

  /// The backend marked the newer build as mandatory; the app is blocked until it is installed.
  required,
}
