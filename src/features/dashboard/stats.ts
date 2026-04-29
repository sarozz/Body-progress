import type { BodyCheckin, Profile } from '@/types';

export interface DashboardStats {
  checkinCount: number;
  currentWeightKg: number | null;
  avg7dWeightKg: number | null;
  weightChange30dKg: number | null;
  waistChange30dCm: number | null;
  bodyFatChange30d: number | null;
  /** 0..1 progress toward the primary goal target weight, if set. */
  goalProgressPct: number | null;
}

const dayDiff = (a: string, b: string) =>
  (new Date(a).getTime() - new Date(b).getTime()) / 86_400_000;

const closestBefore = (
  sorted: BodyCheckin[],
  whenIso: string,
): BodyCheckin | null => {
  for (const c of sorted) {
    if (dayDiff(c.checkinDate, whenIso) <= 0) return c;
  }
  return sorted.length >= 2 ? sorted[sorted.length - 1] : null;
};

export function computeDashboardStats(
  checkins: BodyCheckin[],
  profile: Profile | null,
): DashboardStats {
  if (checkins.length === 0) {
    return {
      checkinCount: 0,
      currentWeightKg: null,
      avg7dWeightKg: null,
      weightChange30dKg: null,
      waistChange30dCm: null,
      bodyFatChange30d: null,
      goalProgressPct: null,
    };
  }

  const sorted = [...checkins].sort((a, b) =>
    b.checkinDate.localeCompare(a.checkinDate),
  );
  const latest = sorted[0];
  const nowIso = new Date().toISOString();

  const last7Weights = sorted
    .filter((c) => dayDiff(nowIso, c.checkinDate) <= 7)
    .map((c) => c.weightKg)
    .filter((w): w is number => w != null);
  const avg7 =
    last7Weights.length === 0
      ? null
      : last7Weights.reduce((a, b) => a + b, 0) / last7Weights.length;

  const ref30Iso = new Date(Date.now() - 30 * 86_400_000).toISOString();
  const ref = closestBefore(sorted, ref30Iso);

  const wDelta =
    latest.weightKg != null && ref?.weightKg != null
      ? latest.weightKg - ref.weightKg
      : null;
  const waistDelta =
    latest.waistCm != null && ref?.waistCm != null
      ? latest.waistCm - ref.waistCm
      : null;
  const bfDelta =
    latest.bodyFatPct != null && ref?.bodyFatPct != null
      ? latest.bodyFatPct - ref.bodyFatPct
      : null;

  let goalProgress: number | null = null;
  const target = profile?.goalTargetWeightKg ?? null;
  if (target != null && latest.weightKg != null && sorted.length >= 2) {
    const start = sorted[sorted.length - 1].weightKg;
    if (start != null && Math.abs(start - target) > 0.01) {
      const progressed = start - latest.weightKg;
      const needed = start - target;
      goalProgress = Math.max(0, Math.min(1, progressed / needed));
    }
  }

  return {
    checkinCount: sorted.length,
    currentWeightKg: latest.weightKg,
    avg7dWeightKg: avg7,
    weightChange30dKg: wDelta,
    waistChange30dCm: waistDelta,
    bodyFatChange30d: bfDelta,
    goalProgressPct: goalProgress,
  };
}
