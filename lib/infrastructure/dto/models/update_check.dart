import 'package:equatable/equatable.dart';

import 'package:eco_task/domain/common/enums/update_need.dart';

/// Outcome of comparing the installed version with the latest release published on the backend.
class UpdateCheck extends Equatable {
  /// Whether, and how strongly, the app must be updated.
  final UpdateNeed need;

  /// Version of the installed build (`1.0.0`).
  final String current;

  /// Newest published version.
  final String latest;

  /// Store page the update is installed from; empty when the backend has none.
  final String storeUrl;

  /// True while the backend flags technical work in progress; the maintenance screen covers the app.
  final bool isMaintenance;

  /// Dialog headline from the backend; empty when the app should use its own text.
  final String title;

  /// Dialog text from the backend; empty when the app should use its own text.
  final String subtitle;

  /// Builds a result from its parts.
  const UpdateCheck({
    required this.need,
    required this.current,
    required this.latest,
    required this.storeUrl,
    this.isMaintenance = false,
    this.title = '',
    this.subtitle = '',
  });

  /// Result for "nothing to do": the installed build is current.
  const UpdateCheck.upToDate(this.current)
    : need = UpdateNeed.none,
      latest = current,
      storeUrl = '',
      isMaintenance = false,
      title = '',
      subtitle = '';

  @override
  List<Object?> get props => [need, current, latest, storeUrl, isMaintenance, title, subtitle];
}
