import type { Session, User } from '@supabase/supabase-js';
import { create } from 'zustand';

import { getSupabase, isSupabaseConfigured } from '@/data/supabase';

interface AuthState {
  ready: boolean;
  user: User | null;
  session: Session | null;
  signUp: (email: string, password: string, displayName?: string) => Promise<void>;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  deleteAccount: () => Promise<void>;
}

export const useAuthStore = create<AuthState>((set) => ({
  ready: false,
  user: null,
  session: null,

  signUp: async (email, password, displayName) => {
    if (!isSupabaseConfigured) throw new Error('Supabase not configured');
    const sb = getSupabase();
    const { data, error } = await sb.auth.signUp({
      email,
      password,
      options: { data: displayName ? { display_name: displayName } : undefined },
    });
    if (error) throw error;
    set({ user: data.user, session: data.session });
  },

  signIn: async (email, password) => {
    if (!isSupabaseConfigured) throw new Error('Supabase not configured');
    const sb = getSupabase();
    const { data, error } = await sb.auth.signInWithPassword({ email, password });
    if (error) throw error;
    set({ user: data.user, session: data.session });
  },

  signOut: async () => {
    if (isSupabaseConfigured) {
      await getSupabase().auth.signOut();
    }
    set({ user: null, session: null });
  },

  deleteAccount: async () => {
    if (!isSupabaseConfigured) throw new Error('Supabase not configured');
    const sb = getSupabase();
    const { error } = await sb.functions.invoke('delete-account');
    if (error) throw error;
    await sb.auth.signOut();
    set({ user: null, session: null });
  },
}));

export function bootstrapAuth() {
  if (!isSupabaseConfigured) {
    useAuthStore.setState({ ready: true });
    return () => {};
  }
  const sb = getSupabase();
  // Fire-and-forget initial fetch.
  sb.auth.getSession().then(({ data }) => {
    useAuthStore.setState({
      ready: true,
      user: data.session?.user ?? null,
      session: data.session ?? null,
    });
  });
  const { data: sub } = sb.auth.onAuthStateChange((_event, session) => {
    useAuthStore.setState({
      ready: true,
      user: session?.user ?? null,
      session: session ?? null,
    });
  });
  return () => sub.subscription.unsubscribe();
}
