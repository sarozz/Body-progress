import {
  formatLength,
  formatWeight,
  lengthFromCm,
  lengthToCm,
  weightFromKg,
  weightToKg,
} from '@/core/units';

describe('units', () => {
  test('metric is identity', () => {
    expect(weightFromKg(80, 'metric')).toBe(80);
    expect(weightToKg(80, 'metric')).toBe(80);
    expect(lengthFromCm(180, 'metric')).toBe(180);
    expect(lengthToCm(180, 'metric')).toBe(180);
  });

  test('imperial round-trip', () => {
    const lb = weightFromKg(80, 'imperial')!;
    expect(weightToKg(lb, 'imperial')).toBeCloseTo(80, 6);
    const inches = lengthFromCm(180, 'imperial')!;
    expect(lengthToCm(inches, 'imperial')).toBeCloseTo(180, 6);
  });

  test('format respects unit', () => {
    expect(formatWeight(80, 'metric')).toContain('kg');
    expect(formatLength(180, 'imperial')).toContain('in');
    expect(formatWeight(null, 'metric')).toBe('—');
  });
});
