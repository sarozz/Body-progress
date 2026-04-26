# Body Progress

Offline-first Flutter app for tracking body measurements over time.
Backed by Supabase (auth, Postgres, Storage) with a local Drift cache so you can log check-ins without a network connection and sync later.

## Features (first slice)

- Email/password signup, login, sign out, account deletion
- User profile (display name, sex, birth date, height)
- Unit selection: metric (kg/cm) or imperial (lb/in) — values are always stored in metric
- Goal setup (type, target weight / waist / body fat, deadline)
- Body check-in form covering every requested measurement
- Measurement history with edit + swipe-to-delete
- Dashboard showing current weight, 7-day average, 30-day weight / waist / body fat changes, goal progress
- Rule-based suggestion engine (no AI, no medical advice)
- Export all data to JSON
- Offline-first: writes go to Drift first, then sync to Supabase when online (with Row-Level Security)

## Project layout

```
lib/
  core/           env + unit conversion
  data/
    local/        Drift database (offline cache)
    models/       Profile, BodyCheckin
    remote/       Supabase service + auth
    repositories/ profile + checkin repos (local-first)
    sync/         pending push + remote pull
  features/
    auth/         signup / login screen
    dashboard/    dashboard + stat calculator
    suggestions/  rule engine
    checkin/      form + history
    profile/      profile, units, goals, export, delete
    shell/        bottom-nav app shell
  state/          Riverpod providers
supabase/
  migrations/     SQL schema + RLS policies
  functions/
    delete-account/ Edge Function for account deletion
test/             Pure-Dart tests for units + suggestion engine
```

## Setup

### 1. Flutter project

This repo contains the Dart sources only. Generate the platform shells once:

```bash
flutter pub get
flutter create . --platforms=android,ios,macos,linux,windows
dart run build_runner build --delete-conflicting-outputs
```

`build_runner` generates `lib/data/local/app_database.g.dart` (Drift).

### 2. Supabase

1. Create a project at https://supabase.com.
2. In the SQL editor, run `supabase/migrations/20260426000000_init.sql`.
3. Deploy the Edge Function:
   ```bash
   supabase functions deploy delete-account
   ```
4. Copy your project URL + anon key into a local `.env` (see `.env.example`).

### 3. Run

Pass Supabase config via `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR-ANON-KEY
```

If you launch without those defines, the app runs in offline-only mode.

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
- "Delete account" calls the `delete-account` Edge Function which removes the auth row and cascades to all data.

## Tests

```bash
flutter test
```

Covers unit conversion round-trips and the suggestion rule engine.
