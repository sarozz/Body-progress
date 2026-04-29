import { evaluateSuggestion } from '@/features/suggestions/engine';
import type { BodyCheckin, Profile } from '@/types';

const todayIso = new Date().toISOString().split('T')[0];
const dateOffset = (days: number) =>
  new Date(Date.now() - days * 86_400_000).toISOString().split('T')[0];

const c = (
  date: string,
  fields: Partial<Pick<BodyCheckin, 'weightKg' | 'waistCm'>> = {},
): BodyCheckin => ({
  id: `${date}-${fields.weightKg ?? 0}-${fields.waistCm ?? 0}`,
  userId: 'u',
  checkinDate: date,
  weightKg: fields.weightKg ?? null,
  bodyFatPct: null,
  chestCm: null,
  waistCm: fields.waistCm ?? null,
  hipsCm: null,
  neckCm: null,
  shouldersCm: null,
  bicepLeftCm: null,
  bicepRightCm: null,
  tricepLeftCm: null,
  tricepRightCm: null,
  forearmLeftCm: null,
  forearmRightCm: null,
  thighLeftCm: null,
  thighRightCm: null,
  calfLeftCm: null,
  calfRightCm: null,
  notes: null,
  photoPath: null,
  createdAt: '2026-01-01T00:00:00Z',
  updatedAt: '2026-01-01T00:00:00Z',
});

describe('suggestion engine', () => {
  test('not enough data when fewer than 3 in last 30 days', () => {
    const s = evaluateSuggestion(
      [c(todayIso, { weightKg: 80 }), c(dateOffset(5), { weightKg: 80 })],
      null,
    );
    expect(s.title).toBe('Not enough data');
  });

  test('flags unrealistic weight jump', () => {
    const s = evaluateSuggestion(
      [
        c(todayIso, { weightKg: 90 }),
        c(dateOffset(1), { weightKg: 80 }),
        c(dateOffset(5), { weightKg: 80 }),
        c(dateOffset(12), { weightKg: 80 }),
      ],
      null,
    );
    expect(s.title).toBe('Possible entry error');
  });

  test('detects recomposition', () => {
    const s = evaluateSuggestion(
      [
        c(todayIso, { weightKg: 80, waistCm: 82 }),
        c(dateOffset(4), { weightKg: 80, waistCm: 83 }),
        c(dateOffset(10), { weightKg: 80.2, waistCm: 84 }),
        c(dateOffset(20), { weightKg: 80.1, waistCm: 85 }),
      ],
      null,
    );
    expect(s.title).toBe('Possible recomposition');
  });

  test('fat-loss stalled triggers consistency suggestion', () => {
    const profile: Profile = {
      id: 'u',
      displayName: null,
      sex: null,
      birthDate: null,
      heightCm: null,
      unitSystem: 'metric',
      goalType: 'lose_fat',
      goalTargetWeightKg: null,
      goalTargetWaistCm: null,
      goalTargetBodyFat: null,
      goalDeadline: null,
      updatedAt: '2026-01-01T00:00:00Z',
    };
    const s = evaluateSuggestion(
      [
        c(todayIso, { weightKg: 80, waistCm: 85 }),
        c(dateOffset(5), { weightKg: 80, waistCm: 85 }),
        c(dateOffset(12), { weightKg: 80, waistCm: 85 }),
      ],
      profile,
    );
    expect(s.title).toBe('Review consistency');
  });
});
