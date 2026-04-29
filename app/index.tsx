import { Redirect } from 'expo-router';
import { ActivityIndicator, StyleSheet, View } from 'react-native';

import { isSupabaseConfigured } from '@/data/supabase';
import { useAuthStore } from '@/state/auth-store';

export default function Index() {
  const { ready, user } = useAuthStore();

  if (!ready) {
    return (
      <View style={styles.center}>
        <ActivityIndicator />
      </View>
    );
  }

  // Offline-only mode (no Supabase configured): jump straight to the app.
  if (!isSupabaseConfigured) return <Redirect href="/(app)/dashboard" />;

  return user ? (
    <Redirect href="/(app)/dashboard" />
  ) : (
    <Redirect href="/(auth)/sign-in" />
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
});
