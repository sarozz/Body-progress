import 'package:body_progress/data/models/body_checkin.dart';
import 'package:body_progress/data/models/profile.dart';
import 'package:body_progress/features/suggestions/suggestion_engine.dart';
import 'package:body_progress/core/units.dart';
import 'package:flutter_test/flutter_test.dart';

BodyCheckin _c(DateTime d, {double? w, double? waist}) => BodyCheckin(
      id: '${d.toIso8601String()}-${w ?? 0}-${waist ?? 0}',
      userId: 'u',
      checkinDate: d,
      weightKg: w,
      waistCm: waist,
    );

void main() {
  const engine = SuggestionEngine();
  final today = DateTime.now();

  test('not enough data when fewer than 3 in last 30 days', () {
    final s = engine.evaluate(
      [_c(today, w: 80), _c(today.subtract(const Duration(days: 5)), w: 80)],
      null,
    );
    expect(s.title, 'Not enough data');
  });

  test('flags unrealistic jump', () {
    final s = engine.evaluate(
      [
        _c(today, w: 90),
        _c(today.subtract(const Duration(days: 1)), w: 80),
        _c(today.subtract(const Duration(days: 5)), w: 80),
        _c(today.subtract(const Duration(days: 12)), w: 80),
      ],
      null,
    );
    expect(s.title, 'Possible entry error');
  });

  test('detects recomposition', () {
    final s = engine.evaluate(
      [
        _c(today, w: 80, waist: 82),
        _c(today.subtract(const Duration(days: 4)), w: 80, waist: 83),
        _c(today.subtract(const Duration(days: 10)), w: 80.2, waist: 84),
        _c(today.subtract(const Duration(days: 20)), w: 80.1, waist: 85),
      ],
      null,
    );
    expect(s.title, 'Possible recomposition');
  });

  test('fat-loss stalled triggers consistency suggestion', () {
    final profile = Profile(
      id: 'u',
      goalType: GoalType.loseFat,
      unitSystem: UnitSystem.metric,
    );
    final s = engine.evaluate(
      [
        _c(today, w: 80.0, waist: 85),
        _c(today.subtract(const Duration(days: 5)), w: 80.0, waist: 85),
        _c(today.subtract(const Duration(days: 12)), w: 80.0, waist: 85),
      ],
      profile,
    );
    expect(s.title, 'Review consistency');
  });
}
