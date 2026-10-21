import '../../../constants/constants.dart';

/// Service a client can request.
enum RequestKind {
  /// Deliver seedlings.
  delivery,

  /// Plant them on site.
  planting,

  /// Garden care.
  care;

  /// Kind parsed from its API name; unknown values fall back to [delivery].
  factory RequestKind.fromJson(Object? name) =>
      values.firstWhere((kind) => kind.name == name, orElse: () => RequestKind.delivery);

  /// Localized label.
  String get title => switch (this) {
    RequestKind.delivery => TrWords.clDelivery.tr(),
    RequestKind.planting => TrWords.clPlanting.tr(),
    RequestKind.care => TrWords.clCare.tr(),
  };

  /// SVG asset of the kind glyph.
  String get icon => switch (this) {
    RequestKind.delivery => AppIcons.truck,
    RequestKind.planting => AppIcons.sprout,
    RequestKind.care => AppIcons.leaf,
  };
}
