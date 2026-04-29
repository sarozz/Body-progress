import { eq } from 'drizzle-orm';

import { getDb } from '@/data/db/client';
import {
  profileFromRow,
  profileFromSupabase,
  profileToRow,
  profileToSupabase,
} from '@/data/db/mappers';
import { profiles } from '@/data/db/schema';
import { getSupabase, isSupabaseConfigured } from '@/data/supabase';
import type { Profile } from '@/types';

export async function loadProfile(userId: string): Promise<Profile | null> {
  const db = await getDb();
  const local = await db
    .select()
    .from(profiles)
    .where(eq(profiles.id, userId))
    .limit(1);
  if (local[0]) return profileFromRow(local[0]);

  if (!isSupabaseConfigured) return null;
  const sb = getSupabase();
  const { data, error } = await sb
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .maybeSingle();
  if (error) throw error;
  if (!data) return null;
  const profile = profileFromSupabase(data);
  await db.insert(profiles).values(profileToRow(profile, 'synced'));
  return profile;
}

export async function saveProfile(profile: Profile): Promise<void> {
  const db = await getDb();
  const next: Profile = {
    ...profile,
    updatedAt: new Date().toISOString(),
  };
  await db
    .insert(profiles)
    .values(profileToRow(next, 'pending'))
    .onConflictDoUpdate({
      target: profiles.id,
      set: profileToRow(next, 'pending'),
    });

  if (!isSupabaseConfigured) return;
  try {
    const sb = getSupabase();
    await sb.from('profiles').upsert(profileToSupabase(next));
    await db
      .update(profiles)
      .set({ syncState: 'synced' })
      .where(eq(profiles.id, profile.id));
  } catch {
    // stays pending; sync service will retry
  }
}
