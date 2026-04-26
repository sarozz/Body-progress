import 'package:body_progress/core/units.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitConverter', () {
    test('metric is identity', () {
      const c = UnitConverter(UnitSystem.metric);
      expect(c.weightFromKg(80), 80);
      expect(c.weightToKg(80), 80);
      expect(c.lengthFromCm(180), 180);
      expect(c.lengthToCm(180), 180);
    });

    test('imperial round-trip', () {
      const c = UnitConverter(UnitSystem.imperial);
      final lb = c.weightFromKg(80);
      expect(c.weightToKg(lb), closeTo(80, 1e-6));
      final inches = c.lengthFromCm(180);
      expect(c.lengthToCm(inches), closeTo(180, 1e-6));
    });

    test('format respects unit', () {
      expect(const UnitConverter(UnitSystem.metric).formatWeight(80),
          contains('kg'));
      expect(const UnitConverter(UnitSystem.imperial).formatLength(180),
          contains('in'));
    });
  });
}
