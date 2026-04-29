import { Redirect, Tabs } from 'expo-router';

import { isSupabaseConfigured } from '@/data/supabase';
import { useAuthStore } from '@/state/auth-store';

export default function AppLayout() {
  const { ready, user } = useAuthStore();
  if (!ready) return null;
  if (isSupabaseConfigured && !user) return <Redirect href="/(auth)/sign-in" />;

  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: '#b39dff',
        tabBarStyle: { backgroundColor: '#1c1b1f', borderTopColor: '#2a292d' },
        headerStyle: { backgroundColor: '#1c1b1f' },
        headerTitleStyle: { color: '#fff' },
        headerTintColor: '#fff',
      }}
    >
      <Tabs.Screen name="dashboard" options={{ title: 'Dashboard' }} />
      <Tabs.Screen name="history" options={{ title: 'History' }} />
      <Tabs.Screen name="profile" options={{ title: 'Profile' }} />
      <Tabs.Screen name="checkin/new" options={{ href: null }} />
      <Tabs.Screen name="checkin/[id]" options={{ href: null }} />
    </Tabs>
  );
}
