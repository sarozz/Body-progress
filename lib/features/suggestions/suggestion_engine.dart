import '../../data/models/body_checkin.dart';
import '../../data/models/profile.dart';

enum SuggestionLevel { info, warn, positive }

class Suggestion {
  const Suggestion(this.level, this.title, this.body);
  final SuggestionLevel level;
  final String title;
  final String body;
}

/// Rule-based engine. NO medical advice, NO AI.
/// Each rule returns at most one Suggestion.
class SuggestionEngine {
  const SuggestionEngine();

  Suggestion evaluate(List<BodyCheckin> checkins, Profile? profile) {
    // Sort newest-first to be safe.
    final sorted = [...checkins]
      ..sort((a, b) => b.checkinDate.compareTo(a.checkinDate));

    final last30 = sorted
        .where((c) =>
            DateTime.now().difference(c.checkinDate).inDays <= 30)
        .toList();

    if (last30.length < 3) {
      return const Suggestion(
        SuggestionLevel.info,
        'Not enough data',
        'Log at least 3 check-ins in 30 days to start seeing meaningful trends.',
      );
    }

    // Detect unrealistic jumps between consecutive entries (within a week).
    for (var i = 0; i < sorted.length - 1; i++) {
      final a = sorted[i];
      final b = sorted[i + 1];
      final days = a.checkinDate.difference(b.checkinDate).inDays.abs();
      if (days == 0 || days > 7) continue;
      if (a.weightKg != null && b.weightKg != null) {
        final perDay = (a.weightKg! - b.weightKg!).abs() / days;
        if (perDay > 1.0) {
          return const Suggestion(
            SuggestionLevel.warn,
            'Possible entry error',
            'A weight change of more than 1 kg/day was detected. Double-check your most recent entries.',
          );
        }
      }
      if (a.waistCm != null && b.waistCm != null) {
        if ((a.waistCm! - b.waistCm!).abs() / days > 2.0) {
          return const Suggestion(
            SuggestionLevel.warn,
            'Possible entry error',
            'Waist changed by more than 2 cm/day. Double-check the units and the latest entries.',
          );
        }
      }
    }

    final newest = sorted.first;
    final ref = _firstWithBoth(sorted.skip(1));
    if (ref != null) {
      final wDelta = (newest.weightKg != null && ref.weightKg != null)
          ? newest.weightKg! - ref.weightKg!
          : null;
      final waistDelta = (newest.waistCm != null && ref.waistCm != null)
          ? newest.waistCm! - ref.waistCm!
          : null;

      // Recomposition: stable weight, decreasing waist
      if (wDelta != null && waistDelta != null) {
        if (wDelta.abs() < 0.5 && waistDelta < -1.0) {
          return const Suggestion(
            SuggestionLevel.positive,
            'Possible recomposition',
            'Weight is roughly stable while waist is trending down — a common signal of body recomposition.',
          );
        }
      }

      // Fat-loss goal stalled
      if (profile?.goalType == GoalType.loseFat) {
        if ((wDelta?.abs() ?? 0) < 0.3 && (waistDelta?.abs() ?? 0) < 0.5) {
          return const Suggestion(
            SuggestionLevel.info,
            'Review consistency',
            'Your fat-loss goal is set but neither weight nor waist has changed much. Consider reviewing intake, training and sleep consistency.',
          );
        }
      }

      // Muscle-gain check
      if (profile?.goalType == GoalType.gainMuscle &&
          wDelta != null &&
          wDelta < 0.1) {
        return const Suggestion(
          SuggestionLevel.info,
          'Gain stalled',
          'Weight is flat or down while your goal is muscle gain. Consider a small calorie surplus.',
        );
      }
    }

    return const Suggestion(
      SuggestionLevel.positive,
      'On track',
      'Keep logging consistently to refine the trend signal.',
    );
  }

  static BodyCheckin? _firstWithBoth(Iterable<BodyCheckin> rest) {
    for (final c in rest) {
      if (c.weightKg != null || c.waistCm != null) return c;
    }
    return null;
  }
}
