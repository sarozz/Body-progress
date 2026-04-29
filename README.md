# Body Progress

Offline-first React Native app for tracking body measurements over time.
Built with **Expo** so you can run it on your phone via **Expo Go** without a
build step. Backed by Supabase (Auth, Postgres, Storage) with a local SQLite
cache (Drizzle ORM + expo-sqlite) so check-ins work offline and sync when you
come back online.

## Features (first slice)

- Email/password signup, login, sign out, account deletion (Edge Function).
- User profile (display name, height, units).
- Unit selection: metric (kg/cm) or imperial (lb/in) — values are always stored in metric.
- Goal setup (type, target weight / waist / body fat).
- Body check-in form covering every requested measurement.
- Measurement history with edit (tap) and delete (long-press).
- Dashboard: current weight, 7-day average, 30-day weight / waist / body-fat changes, goal progress.
- Rule-based suggestion engine (no AI, no medical advice).
- Export all data to JSON via the OS share sheet.
- Offline-first: writes go to local SQLite first, then sync to Supabase. Postgres RLS protects every row.

## Stack

| Concern        | Library                                 |
| -------------- | --------------------------------------- |
| Framework      | Expo (SDK 52) + TypeScript              |
| Routing        | expo-router (file-based, in `app/`)     |
| Backend        | @supabase/supabase-js                   |
| Local DB       | drizzle-orm + expo-sqlite               |
| Server state   | @tanstack/react-query                   |
| Client state   | zustand (auth)                          |
| Forms          | controlled inputs + zod ready           |
| Charts         | react-native-gifted-charts              |

## Project layout

```
app/                       expo-router screens
  _layout.tsx              providers + root stack
  index.tsx                redirect based on auth
  (auth)/sign-in.tsx
  (app)/_layout.tsx        bottom tabs
  (app)/dashboard.tsx
  (app)/history.tsx
  (app)/profile.tsx
  (app)/checkin/new.tsx
  (app)/checkin/[id].tsx
src/
  core/                    env + units
  data/
    db/                    drizzle schema + client + mappers
    repositories/          profile + checkin (local-first)
    sync/                  push pending + pull remote
    supabase.ts
  features/
    dashboard/stats.ts
    suggestions/engine.ts
  state/
    auth-store.ts          zustand
    queries.ts             tanstack-query hooks
  components/              shared UI (StatCard, CheckinForm)
supabase/
  migrations/              SQL schema + RLS
  functions/delete-account/ Edge Function for account deletion
__tests__/                 jest tests for pure logic
```

## Setup

### 1. Install

```bash
npm install
cp .env.example .env
# fill in EXPO_PUBLIC_SUPABASE_URL and EXPO_PUBLIC_SUPABASE_ANON_KEY
```

### 2. Supabase

1. Create a project at https://supabase.com.
2. SQL Editor → run `supabase/migrations/20260426000000_init.sql`.
3. Deploy the Edge Function (optional, only needed for in-app account deletion):
   ```bash
   supabase functions deploy delete-account
   ```

### 3. Run on Expo Go (the easy way)

```bash
npx expo start
```

You'll see a QR code in the terminal:

- **iPhone**: open the **Camera** app, point at the QR code, tap the banner. Expo Go will open and load the app.
- **Android**: open **Expo Go**, tap "Scan QR code".

If your phone is on a different network than your laptop, run with a tunnel:

```bash
npx expo start --tunnel
```

> **Note**: in Expo Go, only `EXPO_PUBLIC_*` env vars are inlined. Set
> `EXPO_PUBLIC_SUPABASE_URL` and `EXPO_PUBLIC_SUPABASE_ANON_KEY` in `.env`
> before starting.

### 4. Run tests

```bash
npm test
npm run typecheck
```

Tests cover the pure logic: unit conversion, dashboard stats, suggestion engine.

## Suggestion rules (current)

- **Not enough data** — fewer than 3 check-ins in the last 30 days.
- **Possible entry error** — weight change > 1 kg/day or waist change > 2 cm/day between consecutive entries.
- **Possible recomposition** — stable weight (< 0.5 kg change) with waist down > 1 cm.
- **Review consistency** — fat-loss goal set, but neither weight nor waist has moved meaningfully.
- **Gain stalled** — muscle-gain goal set, but weight is flat or down.
- **On track** — fallback when no rule fires.

These are observational, not medical advice.

## Privacy

- All measurements and photos are owned by the user.
- Postgres Row-Level Security restricts every table to `auth.uid() = user_id`.
- The `progress-photos` Storage bucket is private; objects must live under a `<user-id>/` prefix and the same RLS rule applies.
- "Delete account" calls the `delete-account` Edge Function, which removes the auth row and cascades to all data via FK.

## Roadmap

- Charts on the dashboard (gifted-charts is already installed).
- Photo capture + private Storage upload.
- Sex / birth-date / goal-deadline pickers in profile.
- Optional AI explanation layer over computed trends.
