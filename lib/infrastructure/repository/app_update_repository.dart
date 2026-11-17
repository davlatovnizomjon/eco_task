import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:eco_task/domain/common/enums/update_need.dart';

import '../common/api_links.dart';
import '../common/dio_client.dart';
import '../dto/models/app_release.dart';
import '../dto/models/update_check.dart';

/// Compares the installed app version with the release the backend publishes for this platform.
class AppUpdateRepository {
  /// Backend name of the running platform, or null where no store update exists (web, desktop).
  String? get _platform {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };
  }

  /// Asks the backend for the latest release and decides how strongly this build must be replaced.
  /// A platform without a store, and a backend with no published release, both mean "up to date".
  Future<UpdateCheck> check() async {
    final current = (await PackageInfo.fromPlatform()).version;
    final platform = _platform;
    if (platform == null) return UpdateCheck.upToDate(current);
    final response = await dioClient.get(ApiLinks.appVersion, queryParameters: {'platform': platform});
    final release = AppRelease.fromJson(response.data as Map<String, dynamic>);
    final need = !isOlder(current, release.latestVersion)
        ? UpdateNeed.none
        : release.forceUpdate
        ? UpdateNeed.required
        : UpdateNeed.optional;
    return UpdateCheck(
      need: need,
      current: current,
      latest: release.latestVersion,
      storeUrl: release.storeUrl,
      isMaintenance: release.isMaintenance,
      title: release.title,
      subtitle: release.subtitle,
    );
  }

  /// True when dotted version [a] is lower than [b]; missing parts count as 0 (`1.2` equals `1.2.0`).
  @visibleForTesting
  static bool isOlder(String a, String b) {
    List<int> parts(String v) => [for (final p in v.split('.')) int.tryParse(p) ?? 0];
    final left = parts(a), right = parts(b);
    for (var i = 0; i < left.length || i < right.length; i++) {
      final x = i < left.length ? left[i] : 0, y = i < right.length ? right[i] : 0;
      if (x != y) return x < y;
    }
    return false;
  }
}
