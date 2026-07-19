-- Run in the Supabase SQL Editor. Safe to rerun.
-- This script never alters auth.users or its triggers.
BEGIN;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS age INTEGER,
  ADD COLUMN IF NOT EXISTS profession TEXT,
  ADD COLUMN IF NOT EXISTS traits TEXT[] DEFAULT '{}'::text[] NOT NULL,
  ADD COLUMN IF NOT EXISTS is_premium BOOLEAN DEFAULT false NOT NULL,
  ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN DEFAULT false NOT NULL,
  ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ DEFAULT now() NOT NULL;

WITH seed AS (
  SELECT
    n,
    (md5('loverage-seed-man-' || n::text))::uuid AS id,
    (ARRAY[
      'Omar','Adam','Youssef','Zayn','Hamza','Ali','Ibrahim','Khalid','Rami','Tariq',
      'Samir','Hassan','Karim','Faris','Nabil','Amir','Bilal','Malik','Rayyan','Zaid'
    ])[n] AS name
  FROM generate_series(1, 20) AS n
)
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, confirmation_token, recovery_token,
  email_change, email_change_token_new
)
SELECT
  '00000000-0000-0000-0000-000000000000'::uuid,
  id,
  'authenticated',
  'authenticated',
  'seed.man.' || n || '@loverage.test',
  '',
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  jsonb_build_object('name', name, 'gender', 'Male'),
  now() - make_interval(days => n),
  now(),
  '', '', '', ''
FROM seed
ON CONFLICT (id) DO UPDATE SET
  raw_user_meta_data = EXCLUDED.raw_user_meta_data,
  updated_at = now();

WITH seed_ids AS (
  SELECT (md5('loverage-seed-man-' || n::text))::uuid AS id
  FROM generate_series(1, 20) AS n
)
DELETE FROM public.profile_photos
WHERE user_id IN (SELECT id FROM seed_ids);

WITH seed_ids AS (
  SELECT (md5('loverage-seed-man-' || n::text))::uuid AS id
  FROM generate_series(1, 20) AS n
)
DELETE FROM public.profiles
WHERE id IN (SELECT id FROM seed_ids);

WITH seed AS (
  SELECT
    n,
    (md5('loverage-seed-man-' || n::text))::uuid AS id,
    (ARRAY[
      'Omar','Adam','Youssef','Zayn','Hamza','Ali','Ibrahim','Khalid','Rami','Tariq',
      'Samir','Hassan','Karim','Faris','Nabil','Amir','Bilal','Malik','Rayyan','Zaid'
    ])[n] AS name
  FROM generate_series(1, 20) AS n
)
INSERT INTO public.profiles (
  id, public_name, gender, religion, bio, public_city,
  public_country_code, verification_status, profile_status,
  profile_completion, age, profession, traits, is_premium,
  is_hidden, created_at, updated_at, last_active_at, last_seen_at
)
SELECT
  id, name, 'Male', 'Islam',
  'Kind, ambitious, and ready for a meaningful relationship.',
  (ARRAY['Dubai','Abu Dhabi','Sharjah','Ajman'])[1 + ((n - 1) % 4)],
  'AE', 'approved', 'active', 100,
  25 + ((n - 1) % 12),
  (ARRAY['Engineer','Founder','Doctor','Designer','Consultant'])[1 + ((n - 1) % 5)],
  ARRAY['Kind','Ambitious','Family-oriented'],
  (n % 5 = 0), false,
  now() - make_interval(days => n), now(), now(), now()
FROM seed;

WITH seed AS (
  SELECT n, (md5('loverage-seed-man-' || n::text))::uuid AS id
  FROM generate_series(1, 20) AS n
)
INSERT INTO public.profile_photos (
  id, user_id, public_url, is_primary, sort_order, moderation_status
)
SELECT
  (md5('loverage-seed-photo-man-' || n::text))::uuid,
  id,
  'https://randomuser.me/api/portraits/men/' || (n + 10) || '.jpg',
  true, 0, 'approved'
FROM seed;

UPDATE public.profiles p
SET main_photo_id = (md5('loverage-seed-photo-man-' || s.n::text))::uuid
FROM generate_series(1, 20) AS s(n)
WHERE p.id = (md5('loverage-seed-man-' || s.n::text))::uuid;

COMMIT;
