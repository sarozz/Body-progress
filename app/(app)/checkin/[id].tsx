import { useLocalSearchParams } from 'expo-router';
import { useMemo } from 'react';
import { ActivityIndicator, StyleSheet, View } from 'react-native';

import { CheckinForm } from '@/components/CheckinForm';
import { useCheckins, useProfile } from '@/state/queries';

export default function EditCheckin() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const checkins = useCheckins();
  const profile = useProfile();
  const units = profile.data?.unitSystem ?? 'metric';

  const existing = useMemo(
    () => checkins.data?.find((c) => c.id === id) ?? null,
    [checkins.data, id],
  );

  if (checkins.isLoading || !existing) {
    return (
      <View style={styles.center}>
        <ActivityIndicator />
      </View>
    );
  }

  return <CheckinForm existing={existing} units={units} />;
}

const styles = StyleSheet.create({
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#1c1b1f',
  },
});
