import { useMemo } from 'react';
import {
  ActivityIndicator,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import { StatCard } from '@/components/StatCard';
import { formatLength, formatWeight } from '@/core/units';
import { computeDashboardStats } from '@/features/dashboard/stats';
import { evaluateSuggestion } from '@/features/suggestions/engine';
import { useCheckins, useProfile } from '@/state/queries';

export default function DashboardScreen() {
  const checkins = useCheckins();
  const profile = useProfile();

  const stats = useMemo(
    () =>
      computeDashboardStats(checkins.data ?? [], profile.data ?? null),
    [checkins.data, profile.data],
  );
  const suggestion = useMemo(
    () => evaluateSuggestion(checkins.data ?? [], profile.data ?? null),
    [checkins.data, profile.data],
  );

  const units = profile.data?.unitSystem ?? 'metric';
  const refreshing = checkins.isFetching || profile.isFetching;

  if (checkins.isLoading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator />
      </View>
    );
  }

  const formatDelta = (
    v: number | null,
    fmt: (n: number | null) => string,
  ) => {
    if (v == null) return '—';
    const sign = v > 0 ? '+' : '';
    return `${sign}${fmt(v)}`;
  };

  const suggestionColor =
    suggestion.level === 'warn'
      ? '#5b1a1a'
      : suggestion.level === 'positive'
        ? '#1d3a2a'
        : '#3a2a4d';

  return (
    <ScrollView
      contentContainerStyle={styles.content}
      refreshControl={
        <RefreshControl
          refreshing={refreshing}
          onRefresh={() => {
            checkins.refetch();
            profile.refetch();
          }}
          tintColor="#fff"
        />
      }
    >
      <StatCard
        title="Current weight"
        value={formatWeight(stats.currentWeightKg, units)}
      />
      <StatCard
        title="7-day avg weight"
        value={formatWeight(stats.avg7dWeightKg, units)}
      />
      <StatCard
        title="30-day weight change"
        value={formatDelta(stats.weightChange30dKg, (n) =>
          formatWeight(n, units),
        )}
      />
      <StatCard
        title="30-day waist change"
        value={formatDelta(stats.waistChange30dCm, (n) =>
          formatLength(n, units),
        )}
      />
      <StatCard
        title="30-day body fat change"
        value={
          stats.bodyFatChange30d == null
            ? '—'
            : `${stats.bodyFatChange30d.toFixed(1)} %`
        }
      />

      {stats.goalProgressPct != null && (
        <View style={styles.goalCard}>
          <Text style={styles.goalLabel}>Goal progress</Text>
          <View style={styles.goalBar}>
            <View
              style={[
                styles.goalFill,
                { width: `${(stats.goalProgressPct * 100).toFixed(0)}%` },
              ]}
            />
          </View>
          <Text style={styles.goalText}>
            {(stats.goalProgressPct * 100).toFixed(0)}% toward target
          </Text>
        </View>
      )}

      <View style={[styles.suggestion, { backgroundColor: suggestionColor }]}>
        <Text style={styles.suggestionTitle}>{suggestion.title}</Text>
        <Text style={styles.suggestionBody}>{suggestion.body}</Text>
      </View>

      <Text style={styles.footer}>
        Logged {stats.checkinCount} check-ins total.
      </Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#1c1b1f',
  },
  content: { padding: 16, backgroundColor: '#1c1b1f', flexGrow: 1 },
  goalCard: {
    backgroundColor: '#2a292d',
    borderRadius: 12,
    padding: 16,
    marginBottom: 10,
  },
  goalLabel: { color: '#bbb', marginBottom: 8 },
  goalBar: {
    height: 8,
    borderRadius: 4,
    backgroundColor: '#1c1b1f',
    overflow: 'hidden',
  },
  goalFill: { height: '100%', backgroundColor: '#7e57ff' },
  goalText: { color: '#fff', marginTop: 8 },
  suggestion: {
    borderRadius: 12,
    padding: 16,
    marginTop: 8,
  },
  suggestionTitle: { color: '#fff', fontSize: 16, fontWeight: '700' },
  suggestionBody: { color: '#ddd', marginTop: 6 },
  footer: { color: '#888', textAlign: 'center', marginTop: 16 },
});
