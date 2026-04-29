-- Body Progress - initial schema
-- All tables are owned by the authenticated user via RLS.

create extension if not exists "pgcrypto";

-- =========================================================================
-- profiles: 1:1 with auth.users
-- =========================================================================
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    display_name text,
    sex text check (sex in ('male','female','other','prefer_not_to_say')),
    birth_date date,
    height_cm numeric(5,2),
    unit_system text not null default 'metric' check (unit_system in ('metric','imperial')),
    -- goal
    goal_type text check (goal_type in ('lose_fat','gain_muscle','recomp','maintain')),
    goal_target_weight_kg numeric(6,2),
    goal_target_waist_cm numeric(6,2),
    goal_target_body_fat numeric(5,2),
    goal_deadline date,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- =========================================================================
-- body_checkins
-- All measurements are stored in METRIC (kg, cm). UI converts on display.
-- =========================================================================
create table if not exists public.body_checkins (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    checkin_date date not null,
    weight_kg numeric(6,2),
    body_fat_pct numeric(5,2),
    chest_cm numeric(6,2),
    waist_cm numeric(6,2),
    hips_cm numeric(6,2),
    neck_cm numeric(6,2),
    shoulders_cm numeric(6,2),
    bicep_left_cm numeric(6,2),
    bicep_right_cm numeric(6,2),
    tricep_left_cm numeric(6,2),
    tricep_right_cm numeric(6,2),
    forearm_left_cm numeric(6,2),
    forearm_right_cm numeric(6,2),
    thigh_left_cm numeric(6,2),
    thigh_right_cm numeric(6,2),
    calf_left_cm numeric(6,2),
    calf_right_cm numeric(6,2),
    notes text,
    photo_path text, -- key in storage bucket "progress-photos"
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists body_checkins_user_date_idx
    on public.body_checkins (user_id, checkin_date desc);

-- updated_at trigger
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists trg_profiles_updated on public.profiles;
create trigger trg_profiles_updated
    before update on public.profiles
    for each row execute function public.set_updated_at();

drop trigger if exists trg_body_checkins_updated on public.body_checkins;
create trigger trg_body_checkins_updated
    before update on public.body_checkins
    for each row execute function public.set_updated_at();

-- =========================================================================
-- Auto-create a profile row on new user signup
-- =========================================================================
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
    insert into public.profiles (id, display_name)
    values (new.id, coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)))
    on conflict (id) do nothing;
    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- =========================================================================
-- Row Level Security
-- =========================================================================
alter table public.profiles enable row level security;
alter table public.body_checkins enable row level security;

drop policy if exists "profiles: read own" on public.profiles;
create policy "profiles: read own"
    on public.profiles for select
    using (auth.uid() = id);

drop policy if exists "profiles: insert own" on public.profiles;
create policy "profiles: insert own"
    on public.profiles for insert
    with check (auth.uid() = id);

drop policy if exists "profiles: update own" on public.profiles;
create policy "profiles: update own"
    on public.profiles for update
    using (auth.uid() = id)
    with check (auth.uid() = id);

drop policy if exists "profiles: delete own" on public.profiles;
create policy "profiles: delete own"
    on public.profiles for delete
    using (auth.uid() = id);

drop policy if exists "checkins: read own" on public.body_checkins;
create policy "checkins: read own"
    on public.body_checkins for select
    using (auth.uid() = user_id);

drop policy if exists "checkins: insert own" on public.body_checkins;
create policy "checkins: insert own"
    on public.body_checkins for insert
    with check (auth.uid() = user_id);

drop policy if exists "checkins: update own" on public.body_checkins;
create policy "checkins: update own"
    on public.body_checkins for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

drop policy if exists "checkins: delete own" on public.body_checkins;
create policy "checkins: delete own"
    on public.body_checkins for delete
    using (auth.uid() = user_id);

-- =========================================================================
-- Storage bucket for progress photos (private, owner-only)
-- =========================================================================
insert into storage.buckets (id, name, public)
values ('progress-photos', 'progress-photos', false)
on conflict (id) do nothing;

drop policy if exists "photos: read own" on storage.objects;
create policy "photos: read own"
    on storage.objects for select
    using (bucket_id = 'progress-photos' and auth.uid()::text = (storage.foldername(name))[1]);

drop policy if exists "photos: insert own" on storage.objects;
create policy "photos: insert own"
    on storage.objects for insert
    with check (bucket_id = 'progress-photos' and auth.uid()::text = (storage.foldername(name))[1]);

drop policy if exists "photos: update own" on storage.objects;
create policy "photos: update own"
    on storage.objects for update
    using (bucket_id = 'progress-photos' and auth.uid()::text = (storage.foldername(name))[1]);

drop policy if exists "photos: delete own" on storage.objects;
create policy "photos: delete own"
    on storage.objects for delete
    using (bucket_id = 'progress-photos' and auth.uid()::text = (storage.foldername(name))[1]);
