import { computeDashboardStats } from '@/features/dashboard/stats';
import type { BodyCheckin } from '@/types';

const stub = (date: string, fields: Partial<BodyCheckin> = {}): BodyCheckin => ({
  id: date,
  userId: 'u',
  checkinDate: date,
  weightKg: null,
  bodyFatPct: null,
  chestCm: null,
  waistCm: null,
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
  createdAt: `${date}T00:00:00Z`,
  updatedAt: `${date}T00:00:00Z`,
  ...fields,
});

describe('computeDashboardStats', () => {
  test('empty checkins returns zeros', () => {
    const s = computeDashboardStats([], null);
    expect(s.checkinCount).toBe(0);
    expect(s.currentWeightKg).toBeNull();
  });

  test('uses newest as current weight', () => {
    const today = new Date().toISOString().split('T')[0];
    const s = computeDashboardStats(
      [stub(today, { weightKg: 78.5 }), stub('2026-01-01', { weightKg: 80 })],
      null,
    );
    expect(s.currentWeightKg).toBe(78.5);
    expect(s.checkinCount).toBe(2);
  });

  test('7-day average uses only recent entries', () => {
    const today = new Date().toISOString().split('T')[0];
    const four = new Date(Date.now() - 4 * 86_400_000)
      .toISOString()
      .split('T')[0];
    const old = new Date(Date.now() - 60 * 86_400_000)
      .toISOString()
      .split('T')[0];
    const s = computeDashboardStats(
      [
        stub(today, { weightKg: 80 }),
        stub(four, { weightKg: 82 }),
        stub(old, { weightKg: 100 }),
      ],
      null,
    );
    expect(s.avg7dWeightKg).toBeCloseTo(81, 5);
  });
});
