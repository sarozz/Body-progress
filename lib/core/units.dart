enum UnitSystem { metric, imperial }

extension UnitSystemX on UnitSystem {
  String get id => switch (this) {
        UnitSystem.metric => 'metric',
        UnitSystem.imperial => 'imperial',
      };

  String get weightLabel => this == UnitSystem.metric ? 'kg' : 'lb';
  String get lengthLabel => this == UnitSystem.metric ? 'cm' : 'in';

  static UnitSystem fromId(String? id) =>
      id == 'imperial' ? UnitSystem.imperial : UnitSystem.metric;
}

/// Conversions between metric storage and the user's display unit.
class UnitConverter {
  const UnitConverter(this.system);
  final UnitSystem system;

  static const double _kgPerLb = 0.45359237;
  static const double _cmPerIn = 2.54;

  /// kg (storage) -> display weight
  double weightFromKg(double? kg) {
    if (kg == null) return 0;
    return system == UnitSystem.metric ? kg : kg / _kgPerLb;
  }

  /// display weight -> kg (storage)
  double weightToKg(double value) =>
      system == UnitSystem.metric ? value : value * _kgPerLb;

  /// cm (storage) -> display length
  double lengthFromCm(double? cm) {
    if (cm == null) return 0;
    return system == UnitSystem.metric ? cm : cm / _cmPerIn;
  }

  /// display length -> cm (storage)
  double lengthToCm(double value) =>
      system == UnitSystem.metric ? value : value * _cmPerIn;

  String formatWeight(double? kg, {int digits = 1}) {
    if (kg == null) return '—';
    return '${weightFromKg(kg).toStringAsFixed(digits)} ${system.weightLabel}';
  }

  String formatLength(double? cm, {int digits = 1}) {
    if (cm == null) return '—';
    return '${lengthFromCm(cm).toStringAsFixed(digits)} ${system.lengthLabel}';
  }
}
