import type { UnitSystem } from '@/core/units';

export type GoalType = 'lose_fat' | 'gain_muscle' | 'recomp' | 'maintain';

export const GOAL_LABEL: Record<GoalType, string> = {
  lose_fat: 'Lose fat',
  gain_muscle: 'Gain muscle',
  recomp: 'Recomposition',
  maintain: 'Maintain',
};

export type Sex = 'male' | 'female' | 'other' | 'prefer_not_to_say';

export interface Profile {
  id: string;
  displayName: string | null;
  sex: Sex | null;
  birthDate: string | null; // ISO date
  heightCm: number | null;
  unitSystem: UnitSystem;
  goalType: GoalType | null;
  goalTargetWeightKg: number | null;
  goalTargetWaistCm: number | null;
  goalTargetBodyFat: number | null;
  goalDeadline: string | null; // ISO date
  updatedAt: string; // ISO timestamp
}

export interface BodyCheckin {
  id: string;
  userId: string;
  checkinDate: string; // ISO date (YYYY-MM-DD)
  weightKg: number | null;
  bodyFatPct: number | null;
  chestCm: number | null;
  waistCm: number | null;
  hipsCm: number | null;
  neckCm: number | null;
  shouldersCm: number | null;
  bicepLeftCm: number | null;
  bicepRightCm: number | null;
  tricepLeftCm: number | null;
  tricepRightCm: number | null;
  forearmLeftCm: number | null;
  forearmRightCm: number | null;
  thighLeftCm: number | null;
  thighRightCm: number | null;
  calfLeftCm: number | null;
  calfRightCm: number | null;
  notes: string | null;
  photoPath: string | null;
  createdAt: string;
  updatedAt: string;
}

export type SyncState = 'pending' | 'synced' | 'deleted';
