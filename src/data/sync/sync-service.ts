import { eq, inArray } from 'drizzle-orm';

import { getDb } from '@/data/db/client';
import {
  checkinFromSupabase,
  checkinToRow,
  checkinToSupabase,
  profileFromSupabase,
  profileToRow,
  profileToSupabase,
} from '@/data/db/mappers';
import { checkins, profiles } from '@/data/db/schema';
import { getSupabase, isSupabaseConfigured } from '@/data/supabase';

let inFlight = false;

/**
 * Push pending local rows, then pull remote rows for the user. Safe to call
 * frequently; concurrent calls are coalesced.
 */
export async function syncNow(): Promise<void> {
  if (inFlight) return;
  if (!isSupabaseConfigured) return;
  const sb = getSupabase();
  const { data: userData } = await sb.auth.getUser();
  const user = userData.user;
  if (!user) return;

  inFlight = true;
  try {
    const db = await getDb();

    // ---- profile push ----
    const profileRows = await db
      .select()
      .from(profiles)
      .where(eq(profiles.id, user.id));
    const localProfile = profileRows[0];
    if (localProfile && localProfile.syncState === 'pending') {
      await sb.from('profiles').upsert(
        profileToSupabase({
          id: localProfile.id,
          displayName: localProfile.displayName,
          sex: (localProfile.sex as never) ?? null,
          birthDate: localProfile.birthDate,
          heightCm: localProfile.heightCm,
          unitSystem: (localProfile.unitSystem as never) ?? 'metric',
          goalType: (localProfile.goalType as never) ?? null,
          goalTargetWeightKg: localProfile.goalTargetWeightKg,
          goalTargetWaistCm: localProfile.goalTargetWaistCm,
          goalTargetBodyFat: localProfile.goalTargetBodyFat,
          goalDeadline: localProfile.goalDeadline,
          updatedAt: localProfile.updatedAt,
        }),
      );
      await db
        .update(profiles)
        .set({ syncState: 'synced' })
        .where(eq(profiles.id, user.id));
    }

    // ---- checkins: deletes ----
    const deletedRows = await db
      .select({ id: checkins.id })
      .from(checkins)
      .where(eq(checkins.syncState, 'deleted'));
    if (deletedRows.length > 0) {
      const ids = deletedRows.map((r) => r.id);
      await sb.from('body_checkins').delete().in('id', ids);
      await db.delete(checkins).where(inArray(checkins.id, ids));
    }

    // ---- checkins: pending upserts ----
    const pendingRows = await db
      .select()
      .from(checkins)
      .where(eq(checkins.syncState, 'pending'));
    if (pendingRows.length > 0) {
      const payload = pendingRows.map((r) =>
        checkinToSupabase({
          id: r.id,
          userId: r.userId,
          checkinDate: r.checkinDate,
          weightKg: r.weightKg,
          bodyFatPct: r.bodyFatPct,
          chestCm: r.chestCm,
          waistCm: r.waistCm,
          hipsCm: r.hipsCm,
          neckCm: r.neckCm,
          shouldersCm: r.shouldersCm,
          bicepLeftCm: r.bicepLeftCm,
          bicepRightCm: r.bicepRightCm,
          tricepLeftCm: r.tricepLeftCm,
          tricepRightCm: r.tricepRightCm,
          forearmLeftCm: r.forearmLeftCm,
          forearmRightCm: r.forearmRightCm,
          thighLeftCm: r.thighLeftCm,
          thighRightCm: r.thighRightCm,
          calfLeftCm: r.calfLeftCm,
          calfRightCm: r.calfRightCm,
          notes: r.notes,
          photoPath: r.photoPath,
          createdAt: r.createdAt,
          updatedAt: r.updatedAt,
        }),
      );
      await sb.from('body_checkins').upsert(payload);
      await db
        .update(checkins)
        .set({ syncState: 'synced' })
        .where(
          inArray(
            checkins.id,
            pendingRows.map((r) => r.id),
          ),
        );
    }

    // ---- pull remote ----
    const { data: remoteCheckins, error: rcErr } = await sb
      .from('body_checkins')
      .select('*')
      .eq('user_id', user.id);
    if (!rcErr && remoteCheckins) {
      for (const row of remoteCheckins) {
        const c = checkinFromSupabase(row as Record<string, unknown>);
        await db
          .insert(checkins)
          .values(checkinToRow(c, 'synced'))
          .onConflictDoUpdate({
            target: checkins.id,
            set: checkinToRow(c, 'synced'),
          });
      }
    }

    const { data: remoteProfile } = await sb
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .maybeSingle();
    if (remoteProfile) {
      const p = profileFromSupabase(remoteProfile as Record<string, unknown>);
      await db
        .insert(profiles)
        .values(profileToRow(p, 'synced'))
        .onConflictDoUpdate({
          target: profiles.id,
          set: profileToRow(p, 'synced'),
        });
    }
  } catch {
    // Swallow: next trigger retries.
  } finally {
    inFlight = false;
  }
}
