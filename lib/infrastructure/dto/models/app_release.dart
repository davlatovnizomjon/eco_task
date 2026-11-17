/// The newest published app build of one platform, as `GET app-version/` returns it.
class AppRelease {
  /// Newest published version (`1.4.0`).
  final String latestVersion;

  /// True when installing the newest build is mandatory.
  final bool forceUpdate;

  /// Store page of the app; empty when none is configured.
  final String storeUrl;

  /// True while the backend has technical work in progress: the app shows the maintenance screen.
  final bool isMaintenance;

  /// Headline of the update dialog written by the admin; empty when the app should use its own text.
  final String title;

  /// Text under the headline (what is new); empty when the app should use its own text.
  final String subtitle;

  /// Builds a release from its parts.
  const AppRelease({
    required this.latestVersion,
    required this.forceUpdate,
    required this.storeUrl,
    this.isMaintenance = false,
    this.title = '',
    this.subtitle = '',
  });

  /// Parses the backend payload `{platform, latest_version, force_update, is_maintenance, store_url, title, subtitle}`.
  factory AppRelease.fromJson(Map<String, dynamic> json) => AppRelease(
    latestVersion: '${json['latest_version']}',
    forceUpdate: json['force_update'] == true,
    storeUrl: '${json['store_url'] ?? ''}',
    isMaintenance: json['is_maintenance'] == true,
    title: '${json['title'] ?? ''}'.trim(),
    subtitle: '${json['subtitle'] ?? ''}'.trim(),
  );
}
