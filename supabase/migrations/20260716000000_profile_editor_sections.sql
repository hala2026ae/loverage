-- Profile editor sections.
-- Adds the variable profile fields used by the mobile editor and allows each
-- authenticated user to manage only their own optional details, traits,
-- interests, and filters.

ALTER TABLE public.profile_optional_details
    ADD COLUMN IF NOT EXISTS country_of_residence TEXT,
    ADD COLUMN IF NOT EXISTS raised_in TEXT,
    ADD COLUMN IF NOT EXISTS willing_to_relocate BOOLEAN DEFAULT false NOT NULL,
    ADD COLUMN IF NOT EXISTS languages_spoken TEXT[] DEFAULT '{}'::TEXT[] NOT NULL,
    ADD COLUMN IF NOT EXISTS body_type TEXT,
    ADD COLUMN IF NOT EXISTS fitness_level TEXT,
    ADD COLUMN IF NOT EXISTS style_of_dress TEXT,
    ADD COLUMN IF NOT EXISTS education_level TEXT,
    ADD COLUMN IF NOT EXISTS field_of_study TEXT,
    ADD COLUMN IF NOT EXISTS job_title TEXT,
    ADD COLUMN IF NOT EXISTS employment_status TEXT,
    ADD COLUMN IF NOT EXISTS pet_lover BOOLEAN DEFAULT false NOT NULL,
    ADD COLUMN IF NOT EXISTS children_count INTEGER,
    ADD COLUMN IF NOT EXISTS wants_children BOOLEAN DEFAULT false NOT NULL,
    ADD COLUMN IF NOT EXISTS family_values TEXT,
    ADD COLUMN IF NOT EXISTS religion_level TEXT;

ALTER TABLE public.user_filters
    ADD COLUMN IF NOT EXISTS preferred_partner_traits TEXT[] DEFAULT '{}'::TEXT[] NOT NULL;

ALTER TABLE public.profile_optional_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_traits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_filters ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own optional details"
    ON public.profile_optional_details;
CREATE POLICY "Users can manage their own optional details"
    ON public.profile_optional_details
    FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can manage their own profile traits"
    ON public.profile_traits;
CREATE POLICY "Users can manage their own profile traits"
    ON public.profile_traits
    FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can manage their own profile interests"
    ON public.profile_interests;
CREATE POLICY "Users can manage their own profile interests"
    ON public.profile_interests
    FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can manage their own filters"
    ON public.user_filters;
CREATE POLICY "Users can manage their own filters"
    ON public.user_filters
    FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
