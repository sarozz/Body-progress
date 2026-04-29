import { Link, useRouter } from 'expo-router';
import {
  ActivityIndicator,
  Alert,
  FlatList,
  Pressable,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import { formatLength, formatWeight } from '@/core/units';
import { useCheckins, useDeleteCheckin, useProfile } from '@/state/queries';
import type { BodyCheckin } from '@/types';

export default function HistoryScreen() {
  const router = useRouter();
  const checkins = useCheckins();
  const profile = useProfile();
  const del = useDeleteCheckin();
  const units = profile.data?.unitSystem ?? 'metric';

  if (checkins.isLoading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator />
      </View>
    );
  }

  const data = checkins.data ?? [];

  return (
    <View style={styles.root}>
      <FlatList
        data={data}
        keyExtractor={(item) => item.id}
        ListEmptyComponent={
          <View style={styles.empty}>
            <Text style={styles.emptyText}>
              No check-ins yet. Tap + to add one.
            </Text>
          </View>
        }
        renderItem={({ item }) => (
          <Row
            item={item}
            units={units}
            onPress={() =>
              router.push({
                pathname: '/(app)/checkin/[id]',
                params: { id: item.id },
              })
            }
            onLongPress={() =>
              Alert.alert('Delete check-in?', 'This cannot be undone.', [
                { text: 'Cancel', style: 'cancel' },
                {
                  text: 'Delete',
                  style: 'destructive',
                  onPress: () => del.mutate(item.id),
                },
              ])
            }
          />
        )}
      />
      <Link href="/(app)/checkin/new" asChild>
        <Pressable style={styles.fab}>
          <Text style={styles.fabText}>+ Check-in</Text>
        </Pressable>
      </Link>
    </View>
  );
}

function Row({
  item,
  units,
  onPress,
  onLongPress,
}: {
  item: BodyCheckin;
  units: 'metric' | 'imperial';
  onPress: () => void;
  onLongPress: () => void;
}) {
  const parts = [
    item.weightKg != null && formatWeight(item.weightKg, units),
    item.waistCm != null && `waist ${formatLength(item.waistCm, units)}`,
    item.bodyFatPct != null && `BF ${item.bodyFatPct.toFixed(1)}%`,
  ].filter(Boolean);

  return (
    <Pressable
      onPress={onPress}
      onLongPress={onLongPress}
      style={({ pressed }) => [styles.row, pressed && { opacity: 0.7 }]}
    >
      <Text style={styles.date}>
        {new Date(item.checkinDate).toDateString()}
      </Text>
      <Text style={styles.subtitle}>{parts.join(' · ')}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#1c1b1f' },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#1c1b1f',
  },
  empty: { padding: 40, alignItems: 'center' },
  emptyText: { color: '#888' },
  row: {
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomColor: '#2a292d',
    borderBottomWidth: 1,
  },
  date: { color: '#fff', fontSize: 16, fontWeight: '600' },
  subtitle: { color: '#bbb', marginTop: 4 },
  fab: {
    position: 'absolute',
    right: 16,
    bottom: 16,
    backgroundColor: '#7e57ff',
    paddingHorizontal: 18,
    paddingVertical: 14,
    borderRadius: 28,
  },
  fabText: { color: '#fff', fontWeight: '600' },
});
