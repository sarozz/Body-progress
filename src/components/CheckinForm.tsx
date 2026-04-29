import { useRouter } from 'expo-router';
import { useState } from 'react';
import {
  Alert,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { v4 as uuidv4 } from 'uuid';

import {
  type UnitSystem,
  lengthLabel,
  lengthFromCm,
  lengthToCm,
  weightLabel,
  weightFromKg,
  weightToKg,
} from '@/core/units';
import { useAuthStore } from '@/state/auth-store';
import { useSaveCheckin } from '@/state/queries';
import type { BodyCheckin } from '@/types';

type FieldKey =
  | 'weight'
  | 'bodyFat'
  | 'chest'
  | 'waist'
  | 'hips'
  | 'neck'
  | 'shoulders'
  | 'bicepLeft'
  | 'bicepRight'
  | 'tricepLeft'
  | 'tricepRight'
  | 'forearmLeft'
  | 'forearmRight'
  | 'thighLeft'
  | 'thighRight'
  | 'calfLeft'
  | 'calfRight';

interface FieldDef {
  key: FieldKey;
  label: string;
  kind: 'weight' | 'length' | 'percent';
}

const FIELDS: FieldDef[] = [
  { key: 'weight', label: 'Weight', kind: 'weight' },
  { key: 'bodyFat', label: 'Body fat %', kind: 'percent' },
  { key: 'chest', label: 'Chest', kind: 'length' },
  { key: 'waist', label: 'Waist', kind: 'length' },
  { key: 'hips', label: 'Hips', kind: 'length' },
  { key: 'neck', label: 'Neck', kind: 'length' },
  { key: 'shoulders', label: 'Shoulders', kind: 'length' },
  { key: 'bicepLeft', label: 'Bicep (L)', kind: 'length' },
  { key: 'bicepRight', label: 'Bicep (R)', kind: 'length' },
  { key: 'tricepLeft', label: 'Tricep (L)', kind: 'length' },
  { key: 'tricepRight', label: 'Tricep (R)', kind: 'length' },
  { key: 'forearmLeft', label: 'Forearm (L)', kind: 'length' },
  { key: 'forearmRight', label: 'Forearm (R)', kind: 'length' },
  { key: 'thighLeft', label: 'Thigh (L)', kind: 'length' },
  { key: 'thighRight', label: 'Thigh (R)', kind: 'length' },
  { key: 'calfLeft', label: 'Calf (L)', kind: 'length' },
  { key: 'calfRight', label: 'Calf (R)', kind: 'length' },
];

const FIELD_TO_CM_KEY: Record<FieldKey, keyof BodyCheckin | null> = {
  weight: null,
  bodyFat: null,
  chest: 'chestCm',
  waist: 'waistCm',
  hips: 'hipsCm',
  neck: 'neckCm',
  shoulders: 'shouldersCm',
  bicepLeft: 'bicepLeftCm',
  bicepRight: 'bicepRightCm',
  tricepLeft: 'tricepLeftCm',
  tricepRight: 'tricepRightCm',
  forearmLeft: 'forearmLeftCm',
  forearmRight: 'forearmRightCm',
  thighLeft: 'thighLeftCm',
  thighRight: 'thighRightCm',
  calfLeft: 'calfLeftCm',
  calfRight: 'calfRightCm',
};

const seedFromCheckin = (
  c: BodyCheckin | null,
  units: UnitSystem,
): Record<FieldKey, string> => {
  const out = {} as Record<FieldKey, string>;
  for (const f of FIELDS) out[f.key] = '';
  if (!c) return out;
  if (c.weightKg != null) out.weight = (weightFromKg(c.weightKg, units) ?? 0).toFixed(1);
  if (c.bodyFatPct != null) out.bodyFat = c.bodyFatPct.toFixed(1);
  for (const f of FIELDS) {
    const cmKey = FIELD_TO_CM_KEY[f.key];
    if (!cmKey) continue;
    const v = c[cmKey] as number | null;
    if (v != null) out[f.key] = (lengthFromCm(v, units) ?? 0).toFixed(1);
  }
  return out;
};

export function CheckinForm({
  existing,
  units,
}: {
  existing: BodyCheckin | null;
  units: UnitSystem;
}) {
  const router = useRouter();
  const userId = useAuthStore((s) => s.user?.id ?? 'local-user');
  const save = useSaveCheckin();

  const [date, setDate] = useState(
    existing?.checkinDate ?? new Date().toISOString().split('T')[0],
  );
  const [notes, setNotes] = useState(existing?.notes ?? '');
  const [values, setValues] = useState<Record<FieldKey, string>>(
    seedFromCheckin(existing, units),
  );

  const set = (key: FieldKey) => (v: string) =>
    setValues((cur) => ({ ...cur, [key]: v.replace(/[^0-9.]/g, '') }));

  const submit = async () => {
    const parseLen = (s: string) => {
      const n = Number.parseFloat(s);
      return Number.isFinite(n) ? lengthToCm(n, units) : null;
    };
    const parseWeight = (s: string) => {
      const n = Number.parseFloat(s);
      return Number.isFinite(n) ? weightToKg(n, units) : null;
    };
    const parsePct = (s: string) => {
      const n = Number.parseFloat(s);
      return Number.isFinite(n) ? n : null;
    };

    const next: BodyCheckin = {
      id: existing?.id ?? uuidv4(),
      userId: existing?.userId ?? userId,
      checkinDate: date,
      weightKg: parseWeight(values.weight),
      bodyFatPct: parsePct(values.bodyFat),
      chestCm: parseLen(values.chest),
      waistCm: parseLen(values.waist),
      hipsCm: parseLen(values.hips),
      neckCm: parseLen(values.neck),
      shouldersCm: parseLen(values.shoulders),
      bicepLeftCm: parseLen(values.bicepLeft),
      bicepRightCm: parseLen(values.bicepRight),
      tricepLeftCm: parseLen(values.tricepLeft),
      tricepRightCm: parseLen(values.tricepRight),
      forearmLeftCm: parseLen(values.forearmLeft),
      forearmRightCm: parseLen(values.forearmRight),
      thighLeftCm: parseLen(values.thighLeft),
      thighRightCm: parseLen(values.thighRight),
      calfLeftCm: parseLen(values.calfLeft),
      calfRightCm: parseLen(values.calfRight),
      notes: notes.trim() || null,
      photoPath: existing?.photoPath ?? null,
      createdAt: existing?.createdAt ?? new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    try {
      await save.mutateAsync(next);
      router.back();
    } catch (e) {
      Alert.alert('Save failed', e instanceof Error ? e.message : String(e));
    }
  };

  const suffix = (kind: FieldDef['kind']) =>
    kind === 'percent'
      ? '%'
      : kind === 'weight'
        ? weightLabel(units)
        : lengthLabel(units);

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.label}>Date (YYYY-MM-DD)</Text>
      <TextInput
        style={styles.input}
        value={date}
        onChangeText={setDate}
        placeholder="2026-04-29"
        placeholderTextColor="#888"
      />

      {FIELDS.map((f) => (
        <View key={f.key} style={styles.fieldRow}>
          <Text style={styles.label}>
            {f.label} ({suffix(f.kind)})
          </Text>
          <TextInput
            style={styles.input}
            keyboardType="decimal-pad"
            value={values[f.key]}
            onChangeText={set(f.key)}
            placeholderTextColor="#888"
          />
        </View>
      ))}

      <Text style={styles.label}>Notes</Text>
      <TextInput
        style={[styles.input, { height: 80 }]}
        multiline
        value={notes}
        onChangeText={setNotes}
        placeholderTextColor="#888"
      />

      <Pressable
        onPress={submit}
        disabled={save.isPending}
        style={({ pressed }) => [
          styles.button,
          (pressed || save.isPending) && { opacity: 0.7 },
        ]}
      >
        <Text style={styles.buttonText}>
          {save.isPending ? 'Saving…' : 'Save check-in'}
        </Text>
      </Pressable>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#1c1b1f' },
  content: { padding: 16 },
  fieldRow: { marginTop: 8 },
  label: { color: '#bbb', marginBottom: 6, marginTop: 8 },
  input: {
    backgroundColor: '#2a292d',
    color: '#fff',
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 8,
  },
  button: {
    marginTop: 24,
    backgroundColor: '#7e57ff',
    paddingVertical: 14,
    borderRadius: 10,
    alignItems: 'center',
  },
  buttonText: { color: '#fff', fontWeight: '600' },
});
