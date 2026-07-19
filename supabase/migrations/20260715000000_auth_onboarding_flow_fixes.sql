-- Auth/onboarding flow fixes.
-- Allows real users to complete registration, submit verification, and accept
-- community rules without service-role bypasses.

CREATE POLICY "Users can insert their own profile"
    ON public.profiles
    FOR INSERT
    WITH CHECK (id = auth.uid());

CREATE POLICY "Users can create their own verification submissions"
    ON public.verification_submissions
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can read their own verification submissions"
    ON public.verification_submissions
    FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can accept and read their own community rules"
    ON public.community_rule_acceptances
    FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE OR REPLACE FUNCTION public.check_profile_status_safety()
RETURNS trigger AS $$
BEGIN
    IF (OLD.verification_status <> NEW.verification_status OR OLD.profile_status <> NEW.profile_status) THEN
        IF (current_setting('role', true) <> 'service_role') THEN
            IF (
                OLD.profile_status = 'registration_incomplete'
                AND NEW.profile_status = 'verification_not_submitted'
                AND NEW.verification_status = 'not_submitted'
            ) THEN
                NULL;
            ELSIF (
                OLD.verification_status = 'not_submitted'
                AND NEW.verification_status = 'pending'
                AND NEW.profile_status = 'verification_pending'
            ) THEN
                NULL;
            ELSIF (NEW.profile_status IN ('deactivated', 'deletion_scheduled')) THEN
                NULL;
            ELSE
                RAISE EXCEPTION 'Permission Denied: Client cannot manually approve or activate profiles.';
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
