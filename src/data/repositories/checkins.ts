import { and, desc, eq, ne } from 'drizzle-orm';

import { getDb } from '@/data/db/client';
import {
  checkinFromRow,
  checkinToRow,
  checkinToSupabase,
} from '@/data/db/mappers';
import { checkins } from '@/data/db/schema';
import { getSupabase, isSupabaseConfigured } from '@/data/supabase';
import type { BodyCheckin } from '@/types';

export async function listCheckins(userId: string): Promise<BodyCheckin[]> {
  const db = await getDb();
  const rows = await db
    .select()
    .from(checkins)
    .where(and(eq(checkins.userId, userId), ne(checkins.syncState, 'deleted')))
    .orderBy(desc(checkins.checkinDate));
  return rows.map(checkinFromRow);
}

export async function saveCheckin(checkin: BodyCheckin): Promise<void> {
  const db = await getDb();
  const next: BodyCheckin = {
    ...checkin,
    updatedAt: new Date().toISOString(),
  };
  await db
    .insert(checkins)
    .values(checkinToRow(next, 'pending'))
    .onConflictDoUpdate({
      target: checkins.id,
      set: checkinToRow(next, 'pending'),
    });

  if (!isSupabaseConfigured) return;
  try {
    const sb = getSupabase();
    await sb.from('body_checkins').upsert(checkinToSupabase(next));
    await db
      .update(checkins)
      .set({ syncState: 'synced' })
      .where(eq(checkins.id, next.id));
  } catch {
    // stays pending
  }
}

export async function deleteCheckin(id: string): Promise<void> {
  const db = await getDb();
  await db
    .update(checkins)
    .set({
      syncState: 'deleted',
      updatedAt: new Date().toISOString(),
    })
    .where(eq(checkins.id, id));

  if (!isSupabaseConfigured) return;
  try {
    const sb = getSupabase();
    await sb.from('body_checkins').delete().eq('id', id);
    await db.delete(checkins).where(eq(checkins.id, id));
  } catch {
    // stays deleted-pending
  }
}
