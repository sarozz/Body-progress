import { useRouter } from 'expo-router';
import { useState } from 'react';
import {
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import { useAuthStore } from '@/state/auth-store';

export default function SignInScreen() {
  const router = useRouter();
  const { signIn, signUp } = useAuthStore();

  const [mode, setMode] = useState<'sign-in' | 'sign-up'>('sign-in');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const submit = async () => {
    setBusy(true);
    setError(null);
    try {
      if (mode === 'sign-up') {
        await signUp(email.trim(), password, displayName.trim() || undefined);
      } else {
        await signIn(email.trim(), password);
      }
      router.replace('/(app)/dashboard');
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(false);
    }
  };

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      style={styles.root}
    >
      <View style={styles.card}>
        <Text style={styles.title}>Body Progress</Text>
        <Text style={styles.subtitle}>
          {mode === 'sign-up' ? 'Create your account' : 'Welcome back'}
        </Text>

        {mode === 'sign-up' && (
          <TextInput
            placeholder="Display name (optional)"
            placeholderTextColor="#888"
            style={styles.input}
            value={displayName}
            onChangeText={setDisplayName}
          />
        )}
        <TextInput
          placeholder="Email"
          placeholderTextColor="#888"
          autoCapitalize="none"
          keyboardType="email-address"
          style={styles.input}
          value={email}
          onChangeText={setEmail}
        />
        <TextInput
          placeholder="Password"
          placeholderTextColor="#888"
          secureTextEntry
          style={styles.input}
          value={password}
          onChangeText={setPassword}
        />

        {error && <Text style={styles.error}>{error}</Text>}

        <Pressable
          onPress={submit}
          disabled={busy}
          style={({ pressed }) => [
            styles.primary,
            (busy || pressed) && { opacity: 0.7 },
          ]}
        >
          {busy ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.primaryText}>
              {mode === 'sign-up' ? 'Sign up' : 'Sign in'}
            </Text>
          )}
        </Pressable>

        <Pressable
          onPress={() => setMode(mode === 'sign-up' ? 'sign-in' : 'sign-up')}
        >
          <Text style={styles.toggle}>
            {mode === 'sign-up'
              ? 'Have an account? Sign in'
              : 'New here? Create an account'}
          </Text>
        </Pressable>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#1c1b1f',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  card: { width: '100%', maxWidth: 420, gap: 12 },
  title: {
    color: '#fff',
    fontSize: 28,
    fontWeight: '700',
    textAlign: 'center',
  },
  subtitle: {
    color: '#bbb',
    textAlign: 'center',
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#2a292d',
    color: '#fff',
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderRadius: 10,
  },
  primary: {
    backgroundColor: '#7e57ff',
    paddingVertical: 14,
    borderRadius: 10,
    alignItems: 'center',
    marginTop: 8,
  },
  primaryText: { color: '#fff', fontWeight: '600' },
  toggle: { color: '#bbb', textAlign: 'center', marginTop: 12 },
  error: { color: '#ff6b6b', textAlign: 'center' },
});
