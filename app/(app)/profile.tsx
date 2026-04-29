import * as FileSystem from 'expo-file-system';
import * as Sharing from 'expo-sharing';
import { useEffect, useState } from 'react';
import {
  Alert,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import {
  type UnitSystem,
  lengthLabel,
  lengthFromCm,
  lengthToCm,
  weightLabel,
  weightFromKg,
  weightToKg,
} from '@/core/units';
import { wipeLocalDb } from '@/data/db/client';
import { isSupabaseConfigured } from '@/data/supabase';
import { useAuthStore } from '@/state/auth-store';
import {
  useCheckins,
  useProfile,
  useSaveProfile,
} from '@/state/queries';
import { type GoalType, GOAL_LABEL, type Profile } from '@/types';

const GOAL_OPTIONS: GoalType[] = ['lose_fat', 'gain_muscle', 'recomp', 'maintain'];
const UNITS: UnitSystem[] = ['metric', 'imperial'];

export default function ProfileScreen() {
  const profile = useProfile();
  const checkins = useCheckins();
  const save = useSaveProfile();
  const { user, signOut, deleteAccount } = useAuthStore();

  const userId = user?.id ?? 'local-user';
  const p = profile.data;

  const [units, setUnits] = useState<UnitSystem>(p?.unitSystem ?? 'metric');
  const [displayName, setDisplayName] = useState(p?.displayName ?? '');
  const [heightStr, setHeightStr] = useState('');
  const [goalType, setGoalType] = useState<GoalType | null>(p?.goalType ?? null);
  const [targetWeight, setTargetWeight] = useState('');
  const [targetWaist, setTargetWaist] = useState('');
  const [targetBf, setTargetBf] = useState('');

  // Hydrate inputs whenever profile or unit system changes.
  useEffect(() => {
    if (!p) return;
    setDisplayName(p.displayName ?? '');
    setUnits(p.unitSystem);
    setGoalType(p.goalType);
    setHeightStr(
      p.heightCm == null
        ? ''
        : (lengthFromCm(p.heightCm, p.unitSystem) ?? 0).toFixed(1),
    );
    setTargetWeight(
      p.goalTargetWeightKg == null
        ? ''
        : (weightFromKg(p.goalTargetWeightKg, p.unitSystem) ?? 0).toFixed(1),
    );
    setTargetWaist(
      p.goalTargetWaistCm == null
        ? ''
        : (lengthFromCm(p.goalTargetWaistCm, p.unitSystem) ?? 0).toFixed(1),
    );
    setTargetBf(
      p.goalTargetBodyFat == null ? '' : p.goalTargetBodyFat.toFixed(1),
    );
  }, [p]);

  const swapUnits = (next: UnitSystem) => {
    if (next === units) return;
    // Re-format inputs in the new unit, but keep stored metric values stable.
    if (p?.heightCm != null)
      setHeightStr((lengthFromCm(p.heightCm, next) ?? 0).toFixed(1));
    if (p?.goalTargetWeightKg != null)
      setTargetWeight((weightFromKg(p.goalTargetWeightKg, next) ?? 0).toFixed(1));
    if (p?.goalTargetWaistCm != null)
      setTargetWaist((lengthFromCm(p.goalTargetWaistCm, next) ?? 0).toFixed(1));
    setUnits(next);
  };

  const submit = async () => {
    const numOrNull = (s: string) => {
      const n = Number.parseFloat(s);
      return Number.isFinite(n) ? n : null;
    };
    const next: Profile = {
      id: userId,
      displayName: displayName.trim() || null,
      sex: p?.sex ?? null,
      birthDate: p?.birthDate ?? null,
      heightCm: numOrNull(heightStr) != null
        ? lengthToCm(numOrNull(heightStr)!, units)
        : null,
      unitSystem: units,
      goalType,
      goalTargetWeightKg: numOrNull(targetWeight) != null
        ? weightToKg(numOrNull(targetWeight)!, units)
        : null,
      goalTargetWaistCm: numOrNull(targetWaist) != null
        ? lengthToCm(numOrNull(targetWaist)!, units)
        : null,
      goalTargetBodyFat: numOrNull(targetBf),
      goalDeadline: p?.goalDeadline ?? null,
      updatedAt: new Date().toISOString(),
    };
    try {
      await save.mutateAsync(next);
      Alert.alert('Saved', 'Profile updated');
    } catch (e) {
      Alert.alert('Save failed', e instanceof Error ? e.message : String(e));
    }
  };

  const exportJson = async () => {
    const payload = JSON.stringify(
      {
        exportedAt: new Date().toISOString(),
        profile: p,
        checkins: checkins.data ?? [],
      },
      null,
      2,
    );
    const path = `${FileSystem.cacheDirectory}body-progress-export.json`;
    await FileSystem.writeAsStringAsync(path, payload, {
      encoding: FileSystem.EncodingType.UTF8,
    });
    if (await Sharing.isAvailableAsync()) {
      await Sharing.shareAsync(path, { mimeType: 'application/json' });
    } else {
      Alert.alert('Saved', `Exported to ${path}`);
    }
  };

  const confirmDelete = () => {
    Alert.alert(
      'Delete account?',
      'This permanently removes your account and all of your data.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteAccount();
            } catch (e) {
              Alert.alert(
                'Remote delete failed',
                e instanceof Error ? e.message : String(e),
              );
            }
            await wipeLocalDb();
          },
        },
      ],
    );
  };

  return (
    <ScrollView
      style={styles.root}
      contentContainerStyle={{ padding: 16, paddingBottom: 80 }}
    >
      <Text style={styles.label}>Display name</Text>
      <TextInput
        style={styles.input}
        value={displayName}
        onChangeText={setDisplayName}
        placeholderTextColor="#888"
      />

      <Text style={[styles.label, { marginTop: 16 }]}>Units</Text>
      <View style={styles.segment}>
        {UNITS.map((u) => (
          <Pressable
            key={u}
            onPress={() => swapUnits(u)}
            style={[styles.segmentItem, units === u && styles.segmentItemActive]}
          >
            <Text
              style={[
                styles.segmentText,
                units === u && styles.segmentTextActive,
              ]}
            >
              {u === 'metric' ? 'kg / cm' : 'lb / in'}
            </Text>
          </Pressable>
        ))}
      </View>

      <Text style={[styles.label, { marginTop: 16 }]}>
        Height ({lengthLabel(units)})
      </Text>
      <TextInput
        style={styles.input}
        keyboardType="decimal-pad"
        value={heightStr}
        onChangeText={setHeightStr}
        placeholderTextColor="#888"
      />

      <Text style={[styles.label, { marginTop: 16 }]}>Goal</Text>
      <View style={styles.segment}>
        {GOAL_OPTIONS.map((g) => (
          <Pressable
            key={g}
            onPress={() => setGoalType(g)}
            style={[styles.segmentItem, goalType === g && styles.segmentItemActive]}
          >
            <Text
              style={[
                styles.segmentText,
                goalType === g && styles.segmentTextActive,
              ]}
            >
              {GOAL_LABEL[g]}
            </Text>
          </Pressable>
        ))}
      </View>

      <Text style={[styles.label, { marginTop: 16 }]}>
        Target weight ({weightLabel(units)})
      </Text>
      <TextInput
        style={styles.input}
        keyboardType="decimal-pad"
        value={targetWeight}
        onChangeText={setTargetWeight}
        placeholderTextColor="#888"
      />

      <Text style={[styles.label, { marginTop: 12 }]}>
        Target waist ({lengthLabel(units)})
      </Text>
      <TextInput
        style={styles.input}
        keyboardType="decimal-pad"
        value={targetWaist}
        onChangeText={setTargetWaist}
        placeholderTextColor="#888"
      />

      <Text style={[styles.label, { marginTop: 12 }]}>Target body fat (%)</Text>
      <TextInput
        style={styles.input}
        keyboardType="decimal-pad"
        value={targetBf}
        onChangeText={setTargetBf}
        placeholderTextColor="#888"
      />

      <Pressable
        onPress={submit}
        disabled={save.isPending}
        style={({ pressed }) => [
          styles.primary,
          (pressed || save.isPending) && { opacity: 0.7 },
        ]}
      >
        <Text style={styles.primaryText}>Save profile</Text>
      </Pressable>

      <Pressable onPress={exportJson} style={styles.outline}>
        <Text style={styles.outlineText}>Export my data (JSON)</Text>
      </Pressable>

      {isSupabaseConfigured && (
        <>
          <Pressable onPress={signOut} style={styles.outline}>
            <Text style={styles.outlineText}>Sign out</Text>
          </Pressable>
          <Pressable onPress={confirmDelete} style={styles.danger}>
            <Text style={styles.dangerText}>Delete account</Text>
          </Pressable>
        </>
      )}

      <Text style={styles.disclaimer}>
        No medical advice. Body Progress provides observational tracking only.
      </Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#1c1b1f' },
  label: { color: '#bbb', marginBottom: 6 },
  input: {
    backgroundColor: '#2a292d',
    color: '#fff',
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 8,
  },
  segment: {
    flexDirection: 'row',
    gap: 8,
    flexWrap: 'wrap',
  },
  segmentItem: {
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 999,
    borderWidth: 1,
    borderColor: '#3a3a40',
  },
  segmentItemActive: { backgroundColor: '#7e57ff', borderColor: '#7e57ff' },
  segmentText: { color: '#bbb' },
  segmentTextActive: { color: '#fff', fontWeight: '600' },
  primary: {
    marginTop: 24,
    backgroundColor: '#7e57ff',
    paddingVertical: 14,
    borderRadius: 10,
    alignItems: 'center',
  },
  primaryText: { color: '#fff', fontWeight: '600' },
  outline: {
    marginTop: 12,
    borderWidth: 1,
    borderColor: '#3a3a40',
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: 'center',
  },
  outlineText: { color: '#fff' },
  danger: {
    marginTop: 12,
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: 'center',
  },
  dangerText: { color: '#ff6b6b' },
  disclaimer: {
    color: '#888',
    textAlign: 'center',
    marginTop: 24,
    fontSize: 12,
  },
});
