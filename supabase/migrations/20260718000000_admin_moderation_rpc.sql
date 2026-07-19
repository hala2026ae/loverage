-- Admin Moderation RPC functions
-- Allows approved administrative workflows to bypass client-level update constraints on status and verification.

-- 1. Update the safety trigger check to allow an admin bypass config flag.
CREATE OR REPLACE FUNCTION public.check_profile_status_safety()
RETURNS trigger AS $$
BEGIN
    -- Check if bypass config is explicitly set in transaction context
    IF (current_setting('my.admin_bypass', true) = 'true') THEN
        RETURN NEW;
    END IF;

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

-- 2. RPC to approve face verification and set user active
CREATE OR REPLACE FUNCTION public.admin_approve_verification(target_user_id UUID)
RETURNS JSONB AS $$
BEGIN
    -- For development: allow any authenticated user to trigger moderation actions.
    -- In production, add a role check here: e.g. IF NOT exists(select 1 from profiles where id = auth.uid() and role = 'admin') THEN ...
    
    -- Set bypass flag for the duration of this local transaction block
    PERFORM set_config('my.admin_bypass', 'true', true);

    -- Update profile status and verification status
    UPDATE public.profiles
    SET verification_status = 'approved',
        profile_status = 'active',
        profile_completion = 100
    WHERE id = target_user_id;

    -- Update latest pending verification submission
    UPDATE public.verification_submissions
    SET status = 'approved',
        reviewed_at = now(),
        reviewed_by = auth.uid()
    WHERE user_id = target_user_id AND status = 'pending';

    -- Trigger notification
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
        target_user_id,
        'verification_approved',
        'Profile Approved!',
        'Your profile verification has been approved. Welcome to Loverage!',
        jsonb_build_object('user_id', target_user_id)
    );

    -- Reset bypass flag
    PERFORM set_config('my.admin_bypass', 'false', true);

    RETURN jsonb_build_object('success', true);
EXCEPTION WHEN OTHERS THEN
    -- Reset bypass flag in case of failure
    PERFORM set_config('my.admin_bypass', 'false', true);
    RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. RPC to reject face verification
CREATE OR REPLACE FUNCTION public.admin_reject_verification(target_user_id UUID, rejection_reason TEXT)
RETURNS JSONB AS $$
BEGIN
    PERFORM set_config('my.admin_bypass', 'true', true);

    UPDATE public.profiles
    SET verification_status = 'rejected',
        profile_status = 'verification_rejected'
    WHERE id = target_user_id;

    UPDATE public.verification_submissions
    SET status = 'rejected',
        rejection_reason = rejection_reason,
        reviewed_at = now(),
        reviewed_by = auth.uid()
    WHERE user_id = target_user_id AND status = 'pending';

    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
        target_user_id,
        'verification_rejected',
        'Verification Rejected',
        COALESCE(rejection_reason, 'Please submit a clearer video to verify your profile.'),
        jsonb_build_object('user_id', target_user_id, 'reason', rejection_reason)
    );

    PERFORM set_config('my.admin_bypass', 'false', true);

    RETURN jsonb_build_object('success', true);
EXCEPTION WHEN OTHERS THEN
    PERFORM set_config('my.admin_bypass', 'false', true);
    RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. RPC to suspend a user profile
CREATE OR REPLACE FUNCTION public.admin_suspend_user(target_user_id UUID, reason TEXT)
RETURNS JSONB AS $$
BEGIN
    PERFORM set_config('my.admin_bypass', 'true', true);

    UPDATE public.profiles
    SET profile_status = 'suspended'
    WHERE id = target_user_id;

    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
        target_user_id,
        'account_suspended',
        'Account Suspended',
        COALESCE(reason, 'Your account has been suspended for community rules violations.'),
        jsonb_build_object('user_id', target_user_id, 'reason', reason)
    );

    PERFORM set_config('my.admin_bypass', 'false', true);

    RETURN jsonb_build_object('success', true);
EXCEPTION WHEN OTHERS THEN
    PERFORM set_config('my.admin_bypass', 'false', true);
    RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. RPC to unsuspend/reactivate a user profile
CREATE OR REPLACE FUNCTION public.admin_unsuspend_user(target_user_id UUID)
RETURNS JSONB AS $$
BEGIN
    PERFORM set_config('my.admin_bypass', 'true', true);

    UPDATE public.profiles
    SET profile_status = 'active'
    WHERE id = target_user_id;

    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
        target_user_id,
        'account_activated',
        'Account Activated',
        'Your account has been reactivated successfully.',
        jsonb_build_object('user_id', target_user_id)
    );

    PERFORM set_config('my.admin_bypass', 'false', true);

    RETURN jsonb_build_object('success', true);
EXCEPTION WHEN OTHERS THEN
    PERFORM set_config('my.admin_bypass', 'false', true);
    RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
