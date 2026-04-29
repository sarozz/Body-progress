import { sql } from 'drizzle-orm';
import { real, sqliteTable, text } from 'drizzle-orm/sqlite-core';

/**
 * Local mirror of the Supabase tables. All measurements are stored in metric
 * (kg, cm); the UI converts on display. Each row carries `syncState` so the
 * sync service knows what to push.
 */
export const profiles = sqliteTable('profiles', {
  id: text('id').primaryKey(),
  displayName: text('display_name'),
  sex: text('sex'),
  birthDate: text('birth_date'),
  heightCm: real('height_cm'),
  unitSystem: text('unit_system').notNull().default('metric'),
  goalType: text('goal_type'),
  goalTargetWeightKg: real('goal_target_weight_kg'),
  goalTargetWaistCm: real('goal_target_waist_cm'),
  goalTargetBodyFat: real('goal_target_body_fat'),
  goalDeadline: text('goal_deadline'),
  updatedAt: text('updated_at')
    .notNull()
    .default(sql`(strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))`),
  syncState: text('sync_state').notNull().default('pending'),
});

export const checkins = sqliteTable('checkins', {
  id: text('id').primaryKey(),
  userId: text('user_id').notNull(),
  checkinDate: text('checkin_date').notNull(),
  weightKg: real('weight_kg'),
  bodyFatPct: real('body_fat_pct'),
  chestCm: real('chest_cm'),
  waistCm: real('waist_cm'),
  hipsCm: real('hips_cm'),
  neckCm: real('neck_cm'),
  shouldersCm: real('shoulders_cm'),
  bicepLeftCm: real('bicep_left_cm'),
  bicepRightCm: real('bicep_right_cm'),
  tricepLeftCm: real('tricep_left_cm'),
  tricepRightCm: real('tricep_right_cm'),
  forearmLeftCm: real('forearm_left_cm'),
  forearmRightCm: real('forearm_right_cm'),
  thighLeftCm: real('thigh_left_cm'),
  thighRightCm: real('thigh_right_cm'),
  calfLeftCm: real('calf_left_cm'),
  calfRightCm: real('calf_right_cm'),
  notes: text('notes'),
  photoPath: text('photo_path'),
  createdAt: text('created_at')
    .notNull()
    .default(sql`(strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))`),
  updatedAt: text('updated_at')
    .notNull()
    .default(sql`(strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))`),
  syncState: text('sync_state').notNull().default('pending'),
});

export type ProfileRow = typeof profiles.$inferSelect;
export type CheckinRow = typeof checkins.$inferSelect;
