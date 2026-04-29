export type UnitSystem = 'metric' | 'imperial';

const KG_PER_LB = 0.45359237;
const CM_PER_IN = 2.54;

export const weightLabel = (u: UnitSystem) => (u === 'metric' ? 'kg' : 'lb');
export const lengthLabel = (u: UnitSystem) => (u === 'metric' ? 'cm' : 'in');

export const weightFromKg = (kg: number | null | undefined, u: UnitSystem) =>
  kg == null ? null : u === 'metric' ? kg : kg / KG_PER_LB;

export const weightToKg = (value: number, u: UnitSystem) =>
  u === 'metric' ? value : value * KG_PER_LB;

export const lengthFromCm = (cm: number | null | undefined, u: UnitSystem) =>
  cm == null ? null : u === 'metric' ? cm : cm / CM_PER_IN;

export const lengthToCm = (value: number, u: UnitSystem) =>
  u === 'metric' ? value : value * CM_PER_IN;

export const formatWeight = (
  kg: number | null | undefined,
  u: UnitSystem,
  digits = 1,
) => {
  const v = weightFromKg(kg, u);
  return v == null ? '—' : `${v.toFixed(digits)} ${weightLabel(u)}`;
};

export const formatLength = (
  cm: number | null | undefined,
  u: UnitSystem,
  digits = 1,
) => {
  const v = lengthFromCm(cm, u);
  return v == null ? '—' : `${v.toFixed(digits)} ${lengthLabel(u)}`;
};
