import { drizzle } from 'drizzle-orm/expo-sqlite';
import * as SQLite from 'expo-sqlite';

import * as schema from './schema';

let _db: ReturnType<typeof drizzle<typeof schema>> | null = null;
let _initPromise: Promise<void> | null = null;

const DB_NAME = 'body_progress.db';

const CREATE_PROFILES = `
  CREATE TABLE IF NOT EXISTS profiles (
    id TEXT PRIMARY KEY,
    display_name TEXT,
    sex TEXT,
    birth_date TEXT,
    height_cm REAL,
    unit_system TEXT NOT NULL DEFAULT 'metric',
    goal_type TEXT,
    goal_target_weight_kg REAL,
    goal_target_waist_cm REAL,
    goal_target_body_fat REAL,
    goal_deadline TEXT,
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    sync_state TEXT NOT NULL DEFAULT 'pending'
  );
`;

const CREATE_CHECKINS = `
  CREATE TABLE IF NOT EXISTS checkins (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    checkin_date TEXT NOT NULL,
    weight_kg REAL,
    body_fat_pct REAL,
    chest_cm REAL,
    waist_cm REAL,
    hips_cm REAL,
    neck_cm REAL,
    shoulders_cm REAL,
    bicep_left_cm REAL,
    bicep_right_cm REAL,
    tricep_left_cm REAL,
    tricep_right_cm REAL,
    forearm_left_cm REAL,
    forearm_right_cm REAL,
    thigh_left_cm REAL,
    thigh_right_cm REAL,
    calf_left_cm REAL,
    calf_right_cm REAL,
    notes TEXT,
    photo_path TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    sync_state TEXT NOT NULL DEFAULT 'pending'
  );
`;

const CREATE_INDEX = `
  CREATE INDEX IF NOT EXISTS checkins_user_date_idx
    ON checkins (user_id, checkin_date DESC);
`;

async function ensureSchema(raw: SQLite.SQLiteDatabase) {
  await raw.execAsync(CREATE_PROFILES);
  await raw.execAsync(CREATE_CHECKINS);
  await raw.execAsync(CREATE_INDEX);
}

export async function getDb() {
  if (_db) return _db;
  if (!_initPromise) {
    _initPromise = (async () => {
      const raw = await SQLite.openDatabaseAsync(DB_NAME);
      await ensureSchema(raw);
      _db = drizzle(raw, { schema });
    })();
  }
  await _initPromise;
  return _db!;
}

/** Wipe all local data (used by sign-out / delete-account). */
export async function wipeLocalDb() {
  const raw = await SQLite.openDatabaseAsync(DB_NAME);
  await raw.execAsync('DELETE FROM checkins; DELETE FROM profiles;');
}
