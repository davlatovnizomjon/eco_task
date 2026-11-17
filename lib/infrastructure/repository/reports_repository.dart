import '../../domain/common/enums/report_period.dart';
import '../common/api_cache.dart';
import '../common/api_links.dart';
import '../dto/models/dashboard_summary.dart';
import '../dto/models/profile_summary.dart';
import '../../domain/common/enums/stats_kind.dart';
import '../../domain/common/enums/stats_period.dart';
import '../dto/models/report_summary.dart';
import '../dto/models/stats_report.dart';

import 'package:eco_task/infrastructure/common/dio_client.dart';

/// Aggregated numbers: the boss dashboard, reports and the profile summary.
class ReportsRepository {
  /// Cached dashboard, or null before the first load.
  DashboardSummary? cachedDashboard() => ApiCache.read<DashboardSummary>('dashboard');

  /// Loads the dashboard numbers of the signed-in boss's scope.
  Future<DashboardSummary> getDashboard() async {
    final response = await dioClient.get(ApiLinks.dashboard);
    return ApiCache.write('dashboard', DashboardSummary.fromJson(response.data as Map<String, dynamic>));
  }

  /// Cached report of [period], or null before the first load.
  ReportSummary? cachedReport(ReportPeriod period) => ApiCache.read<ReportSummary>('report|${period.name}');

  /// Loads the aggregated report of [period].
  Future<ReportSummary> getReport(ReportPeriod period) async {
    final response = await dioClient.get(ApiLinks.reports, queryParameters: {'period': period.name});
    return ApiCache.write('report|${period.name}', ReportSummary.fromJson(response.data as Map<String, dynamic>));
  }

  /// Cache key of one statistics screen for one window.
  static String _statsKey(StatsKind kind, StatsPeriod period, int offset) =>
      'stats|${kind.name}|${period.name}|$offset';

  /// Cached statistics of [kind] for the window, or null when it was never loaded.
  StatsReport? cachedStats(StatsKind kind, StatsPeriod period, int offset) =>
      ApiCache.read<StatsReport>(_statsKey(kind, period, offset));

  /// Loads the statistics of [kind] for the window [offset] periods from the current one.
  Future<StatsReport> getStats(StatsKind kind, StatsPeriod period, int offset) async {
    final response = await dioClient.get(
      ApiLinks.stats,
      queryParameters: {'kind': kind.name, 'period': period.name, 'offset': offset},
    );
    return ApiCache.write(_statsKey(kind, period, offset), StatsReport.fromJson(response.data as Map<String, dynamic>));
  }

  /// Asks the server to prepare the downloadable file of a statistics screen.
  Future<void> exportStats(StatsKind kind, StatsPeriod period, int offset) =>
      dioClient.post(ApiLinks.statsExport, data: {'kind': kind.name, 'period': period.name, 'offset': offset});

  /// Cached profile numbers, or null before the first load.
  ProfileSummary? cachedProfile() => ApiCache.read<ProfileSummary>('profile');

  /// Loads the profile screen's numbers for the signed-in role.
  Future<ProfileSummary> getProfile() async {
    final response = await dioClient.get(ApiLinks.profileSummary);
    return ApiCache.write('profile', ProfileSummary.fromJson(response.data as Map<String, dynamic>));
  }
}
