import '../../../constants/constants.dart';

/// Category a worker picks when entering an expense.
enum ExpenseKind {
  /// Fuel, taxi, delivery costs.
  transport,

  /// Soil, packaging and other materials.
  material,

  /// Anything else.
  other;

  /// Kind parsed from its API name; unknown values fall back to [other].
  factory ExpenseKind.fromJson(Object? name) =>
      values.firstWhere((kind) => kind.name == name, orElse: () => ExpenseKind.other);

  /// Localized label.
  String get title => switch (this) {
    ExpenseKind.transport => TrWords.expTransport.tr(),
    ExpenseKind.material => TrWords.expMaterial.tr(),
    ExpenseKind.other => TrWords.expOther.tr(),
  };

  /// SVG asset of the kind glyph.
  String get icon => switch (this) {
    ExpenseKind.transport => AppIcons.truck,
    ExpenseKind.material => AppIcons.sprout,
    ExpenseKind.other => AppIcons.more,
  };
}
