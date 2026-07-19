-- Adds/replaces images for the 40 Loverage seed profiles. Safe to rerun.
BEGIN;

WITH seed AS (
  SELECT
    n,
    (md5('loverage-seed-man-' || n::text))::uuid AS user_id
  FROM generate_series(1, 20) AS n
  UNION ALL
  SELECT
    n + 20,
    (md5('loverage-seed-woman-' || n::text))::uuid AS user_id
  FROM generate_series(1, 20) AS n
)
DELETE FROM public.profile_photos p
USING seed s
WHERE p.user_id = s.user_id;

WITH seed AS (
  SELECT
    n,
    (md5('loverage-seed-man-' || n::text))::uuid AS user_id,
    (md5('loverage-seed-photo-man-' || n::text))::uuid AS photo_id,
    'https://randomuser.me/api/portraits/men/' || (n + 10) || '.jpg' AS url
  FROM generate_series(1, 20) AS n
  UNION ALL
  SELECT
    n,
    (md5('loverage-seed-woman-' || n::text))::uuid AS user_id,
    (md5('loverage-seed-photo-woman-' || n::text))::uuid AS photo_id,
    'https://randomuser.me/api/portraits/women/' || (n + 10) || '.jpg' AS url
  FROM generate_series(1, 20) AS n
)
INSERT INTO public.profile_photos (
  id, user_id, public_url, is_primary, sort_order, moderation_status
)
SELECT photo_id, user_id, url, true, 0, 'approved'
FROM seed
WHERE EXISTS (
  SELECT 1 FROM public.profiles p WHERE p.id = seed.user_id
);

WITH seed AS (
  SELECT
    (md5('loverage-seed-man-' || n::text))::uuid AS user_id,
    (md5('loverage-seed-photo-man-' || n::text))::uuid AS photo_id
  FROM generate_series(1, 20) AS n
  UNION ALL
  SELECT
    (md5('loverage-seed-woman-' || n::text))::uuid AS user_id,
    (md5('loverage-seed-photo-woman-' || n::text))::uuid AS photo_id
  FROM generate_series(1, 20) AS n
)
UPDATE public.profiles p
SET main_photo_id = seed.photo_id,
    updated_at = now(),
    last_seen_at = now()
FROM seed
WHERE p.id = seed.user_id;

COMMIT;

-- Verification: should return 40.
SELECT count(*) AS seeded_profiles_with_images
FROM public.profiles p
JOIN public. ph ON ph.id = p.main_photo_id
WHERE p.id IN (
  SELECT (md5('loverage-seed-man-' || n::text))::uuid
  FROM generate_series(1, 20) AS n
  UNION ALL
  SELECT (md5('loverage-seed-woman-' || n::text))::uuid
  FROM generate_series(1, 20) AS n
);
