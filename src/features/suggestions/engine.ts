import type { BodyCheckin, Profile } from '@/types';

export type SuggestionLevel = 'info' | 'warn' | 'positive';

export interface Suggestion {
  level: SuggestionLevel;
  title: string;
  body: string;
}

const dayDiff = (a: string, b: string) =>
  Math.abs((new Date(a).getTime() - new Date(b).getTime()) / 86_400_000);

/**
 * Rule-based suggestion engine. No AI. No medical advice.
 * Returns at most one suggestion based on the highest-priority rule that fires.
 */
export function evaluateSuggestion(
  checkins: BodyCheckin[],
  profile: Profile | null,
): Suggestion {
  const sorted = [...checkins].sort((a, b) =>
    b.checkinDate.localeCompare(a.checkinDate),
  );

  const last30 = sorted.filter(
    (c) => dayDiff(new Date().toISOString(), c.checkinDate) <= 30,
  );

  if (last30.length < 3) {
    return {
      level: 'info',
      title: 'Not enough data',
      body: 'Log at least 3 check-ins in 30 days to start seeing meaningful trends.',
    };
  }

  for (let i = 0; i < sorted.length - 1; i++) {
    const a = sorted[i];
    const b = sorted[i + 1];
    const days = dayDiff(a.checkinDate, b.checkinDate);
    if (days === 0 || days > 7) continue;
    if (a.weightKg != null && b.weightKg != null) {
      const perDay = Math.abs(a.weightKg - b.weightKg) / days;
      if (perDay > 1.0) {
        return {
          level: 'warn',
          title: 'Possible entry error',
          body: 'A weight change of more than 1 kg/day was detected. Double-check your most recent entries.',
        };
      }
    }
    if (a.waistCm != null && b.waistCm != null) {
      if (Math.abs(a.waistCm - b.waistCm) / days > 2.0) {
        return {
          level: 'warn',
          title: 'Possible entry error',
          body: 'Waist changed by more than 2 cm/day. Double-check the units and the latest entries.',
        };
      }
    }
  }

  const newest = sorted[0];
  const ref = sorted
    .slice(1)
    .find((c) => c.weightKg != null || c.waistCm != null);

  if (ref) {
    const wDelta =
      newest.weightKg != null && ref.weightKg != null
        ? newest.weightKg - ref.weightKg
        : null;
    const waistDelta =
      newest.waistCm != null && ref.waistCm != null
        ? newest.waistCm - ref.waistCm
        : null;

    if (wDelta != null && waistDelta != null) {
      if (Math.abs(wDelta) < 0.5 && waistDelta < -1.0) {
        return {
          level: 'positive',
          title: 'Possible recomposition',
          body: 'Weight is roughly stable while waist is trending down — a common signal of body recomposition.',
        };
      }
    }

    if (profile?.goalType === 'lose_fat') {
      if (
        Math.abs(wDelta ?? 0) < 0.3 &&
        Math.abs(waistDelta ?? 0) < 0.5
      ) {
        return {
          level: 'info',
          title: 'Review consistency',
          body: 'Your fat-loss goal is set but neither weight nor waist has changed much. Consider reviewing intake, training and sleep consistency.',
        };
      }
    }

    if (profile?.goalType === 'gain_muscle' && wDelta != null && wDelta < 0.1) {
      return {
        level: 'info',
        title: 'Gain stalled',
        body: 'Weight is flat or down while your goal is muscle gain. Consider a small calorie surplus.',
      };
    }
  }

  return {
    level: 'positive',
    title: 'On track',
    body: 'Keep logging consistently to refine the trend signal.',
  };
}
