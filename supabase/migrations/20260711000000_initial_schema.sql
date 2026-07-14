-- Lovest Schema Migration
-- Initial Production Database Setup

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Define custom enum types (represented as TEXT checks for flexibility in migration, but locked with constraints)
-- Let's set up the tables:

-- 1. Public Profile Data (exposability restricted by RLS)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    public_name TEXT NOT NULL,
    gender TEXT NOT NULL CONSTRAINT check_gender CHECK (gender IN ('Male', 'Female')),
    religion TEXT NOT NULL CONSTRAINT check_religion CHECK (religion IN ('Islam', 'Christianity', 'Judaism')),
    bio TEXT CONSTRAINT check_bio_length CHECK (char_length(bio) <= 500),
    public_city TEXT NOT NULL,
    public_country_code VARCHAR(2) NOT NULL,
    verification_status TEXT DEFAULT 'not_submitted' CONSTRAINT check_verification_status CHECK (verification_status IN ('not_submitted', 'pending', 'approved', 'rejected')),
    profile_status TEXT DEFAULT 'registration_incomplete' CONSTRAINT check_profile_status CHECK (profile_status IN ('registration_incomplete', 'verification_not_submitted', 'verification_pending', 'active', 'suspended', 'deactivated', 'deletion_scheduled')),
    profile_completion INTEGER DEFAULT 0 CONSTRAINT check_completion_range CHECK (profile_completion BETWEEN 0 AND 100),
    main_image_id UUID, -- References profile_images(id) but added later to avoid circular constraint
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    last_active_at TIMESTAMPTZ
);

-- 2. Private User Data (Never exposed to other users)
CREATE TABLE public.private_user_data (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    date_of_birth DATE NOT NULL CONSTRAINT check_age_limit CHECK (date_of_birth <= CURRENT_DATE - INTERVAL '18 years'),
    exact_latitude NUMERIC(9, 6),
    exact_longitude NUMERIC(9, 6),
    coarse_geohash VARCHAR(12),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 3. Profile Images (Only approved images appear in public feed)
CREATE TABLE public.profile_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    storage_path TEXT NOT NULL,
    is_main BOOLEAN DEFAULT false NOT NULL,
    moderation_status TEXT DEFAULT 'pending' CONSTRAINT check_moderation_status CHECK (moderation_status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Complete circular dependency for profiles
ALTER TABLE public.profiles ADD CONSTRAINT fk_profiles_main_image FOREIGN KEY (main_image_id) REFERENCES public.profile_images(id) ON DELETE SET NULL;

-- 4. Profile Optional Details
CREATE TABLE public.profile_optional_details (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    marital_status TEXT CONSTRAINT check_marital CHECK (marital_status IN ('Never married', 'Separated', 'Divorced', 'Annulled', 'Widowed', 'Prefer not to say')),
    children TEXT CONSTRAINT check_children CHECK (children IN ('No', 'Yes', 'Prefer not to say')),
    drinking TEXT CONSTRAINT check_drinking CHECK (drinking IN ('No', 'Yes', 'Prefer not to say')),
    smoking TEXT CONSTRAINT check_smoking CHECK (smoking IN ('No', 'Yes', 'Prefer not to say')),
    height INTEGER CONSTRAINT check_height CHECK (height BETWEEN 50 AND 250), -- in cm
    weight INTEGER CONSTRAINT check_weight CHECK (weight BETWEEN 30 AND 300), -- in kg
    nationality TEXT,
    upbringing_country TEXT,
    education TEXT CONSTRAINT check_education CHECK (education IN ('High school', 'Diploma', 'Bachelor’s degree', 'Master’s degree', 'Doctorate', 'Vocational education', 'Other', 'Prefer not to say')),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 5. Profile Traits & Interests (relational models)
CREATE TABLE public.profile_traits (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    trait TEXT NOT NULL,
    PRIMARY KEY (user_id, trait)
);

CREATE TABLE public.profile_interests (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    interest TEXT NOT NULL,
    PRIMARY KEY (user_id, interest)
);

-- 6. User Filters (persisted client preferences)
CREATE TABLE public.user_filters (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    min_age INTEGER DEFAULT 18 NOT NULL CHECK (min_age >= 18),
    max_age INTEGER DEFAULT 99 NOT NULL CHECK (max_age >= min_age),
    religion TEXT,
    country TEXT,
    city TEXT,
    max_distance_km INTEGER,
    nationality TEXT,
    marital_status TEXT,
    has_children TEXT,
    smoking TEXT,
    drinking TEXT,
    education TEXT,
    min_height INTEGER DEFAULT 50,
    max_height INTEGER DEFAULT 250,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 7. Verification Submissions (private 5-sec video path and reviewer notes)
CREATE TABLE public.verification_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    video_storage_path TEXT NOT NULL,
    status TEXT DEFAULT 'pending' CONSTRAINT check_verification_status CHECK (status IN ('pending', 'approved', 'rejected')),
    submitted_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID,
    rejection_reason TEXT,
    attempt_number INTEGER DEFAULT 1 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 8. Community Rules Acceptance
CREATE TABLE public.community_rule_acceptances (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    rules_version TEXT NOT NULL,
    accepted_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    locale VARCHAR(5),
    app_version TEXT
);

-- 9. Matching and Engagement (Knocks & Chat Requests)
CREATE TABLE public.knocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    receiver_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    status TEXT DEFAULT 'pending' CONSTRAINT check_knock_status CHECK (status IN ('pending', 'approved', 'declined', 'cancelled', 'expired')),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT check_self_knock CHECK (sender_id <> receiver_id)
);

-- Prevent duplicate active pending knocks between two users
CREATE UNIQUE INDEX unique_pending_knock ON public.knocks(sender_id, receiver_id) WHERE status = 'pending';

CREATE TABLE public.chat_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    receiver_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    introduction VARCHAR(300) NOT NULL,
    status TEXT DEFAULT 'pending' CONSTRAINT check_request_status CHECK (status IN ('pending', 'accepted', 'declined', 'cancelled', 'expired')),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT check_self_request CHECK (sender_id <> receiver_id)
);

CREATE UNIQUE INDEX unique_pending_chat_request ON public.chat_requests(sender_id, receiver_id) WHERE status = 'pending';

-- 10. Real-Time Conversations & Messaging
CREATE TABLE public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    last_message_preview TEXT,
    last_message_at TIMESTAMPTZ,
    last_sender_id UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

CREATE TABLE public.conversation_members (
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    unread_count INTEGER DEFAULT 0 NOT NULL,
    last_read_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    is_muted BOOLEAN DEFAULT false NOT NULL,
    PRIMARY KEY (conversation_id, user_id)
);

CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL CONSTRAINT check_message_content CHECK (char_length(content) > 0 AND char_length(content) <= 2000),
    idempotency_key TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE UNIQUE INDEX unique_message_idempotency ON public.messages (conversation_id, idempotency_key) WHERE idempotency_key IS NOT NULL;

-- 11. Notification Center (Push triggers write to this table)
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 12. Push Notification Device Registration
CREATE TABLE public.device_tokens (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    fcm_token TEXT NOT NULL,
    platform TEXT NOT NULL,
    device_id_hash TEXT NOT NULL,
    app_version TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    last_seen_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    revoked_at TIMESTAMPTZ,
    PRIMARY KEY (user_id, device_id_hash)
);

-- 13. Daily Anti-Spam Rate Limits (Free account controls)
CREATE TABLE public.daily_usage (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    usage_date DATE DEFAULT CURRENT_DATE NOT NULL,
    knocks_sent INTEGER DEFAULT 0 NOT NULL,
    chat_requests_sent INTEGER DEFAULT 0 NOT NULL,
    PRIMARY KEY (user_id, usage_date)
);

-- 14. Subscriptions & Billing Events (Server-Authoritative Entitlements)
CREATE TABLE public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    platform TEXT NOT NULL,
    product_id TEXT NOT NULL,
    status TEXT NOT NULL CONSTRAINT check_sub_status CHECK (status IN ('pending', 'active', 'grace_period', 'billing_retry', 'on_hold', 'paused', 'cancelled', 'expired', 'revoked', 'refunded')),
    entitlement TEXT NOT NULL CONSTRAINT check_entitlement CHECK (entitlement IN ('free', 'premium')),
    original_transaction_id TEXT NOT NULL,
    latest_transaction_id TEXT NOT NULL,
    purchase_token_hash TEXT,
    started_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    current_period_start TIMESTAMPTZ DEFAULT now() NOT NULL,
    current_period_end TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    grace_period_expires_at TIMESTAMPTZ,
    auto_renewing BOOLEAN DEFAULT true NOT NULL,
    environment TEXT DEFAULT 'production' NOT NULL,
    last_verified_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE public.subscription_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    platform TEXT NOT NULL,
    event_type TEXT NOT NULL,
    product_id TEXT,
    transaction_reference TEXT,
    event_timestamp TIMESTAMPTZ NOT NULL,
    received_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    processed_at TIMESTAMPTZ,
    processing_status TEXT DEFAULT 'pending',
    payload_reference TEXT,
    error_message TEXT
);

-- 15. Safety: Blocks & Reports
CREATE TABLE public.blocks (
    blocker_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    blocked_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    PRIMARY KEY (blocker_id, blocked_id),
    CONSTRAINT check_self_block CHECK (blocker_id <> blocked_id)
);

CREATE TABLE public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reported_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    reason TEXT NOT NULL CONSTRAINT check_report_reason CHECK (reason IN ('Fake profile', 'Inappropriate photos', 'Sexual or offensive messages', 'Harassment', 'Scam or asking for money', 'Underage concern', 'Dishonest relationship status', 'Threatening behavior', 'Other')),
    description TEXT,
    status TEXT DEFAULT 'pending' CONSTRAINT check_report_status CHECK (status IN ('pending', 'under_review', 'resolved', 'dismissed')),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);


-- ==========================================
-- TRIGGERS & FUNCTIONS
-- ==========================================

-- A. Auto Update Timestamp Helper
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_timestamp BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_private_user_data_timestamp BEFORE UPDATE ON public.private_user_data FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_optional_details_timestamp BEFORE UPDATE ON public.profile_optional_details FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_user_filters_timestamp BEFORE UPDATE ON public.user_filters FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_knocks_timestamp BEFORE UPDATE ON public.knocks FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_chat_requests_timestamp BEFORE UPDATE ON public.chat_requests FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_subscriptions_timestamp BEFORE UPDATE ON public.subscriptions FOR EACH ROW EXECUTE FUNCTION update_modified_column();

-- B. Handle New User Trigger (Initial account setup on sign-up)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Insert into public.profiles
  INSERT INTO public.profiles (id, public_name, gender, religion, public_city, public_country_code, profile_status)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'name', 'New Member'),
    COALESCE(new.raw_user_meta_data->>'gender', 'Male'), -- Initial default, confirmed during registration
    'Islam', -- Initial default
    'City', 
    'US',
    'registration_incomplete'
  );

  -- Insert into public.private_user_data
  INSERT INTO public.private_user_data (user_id, date_of_birth)
  VALUES (
    new.id,
    '2000-01-01' -- Temporary placeholder, updated during onboarding DOB step
  );

  -- Initialize filters
  INSERT INTO public.user_filters (user_id)
  VALUES (new.id);

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- C. Security Guard: Prevent direct client modification of status/verification fields
CREATE OR REPLACE FUNCTION public.check_profile_status_safety()
RETURNS trigger AS $$
BEGIN
    IF (OLD.verification_status <> NEW.verification_status OR OLD.profile_status <> NEW.profile_status) THEN
        -- If execution is not by a service role/admin (e.g. standard user client token)
        IF (current_setting('role', true) <> 'service_role') THEN
            -- Allow submitting verification
            IF (OLD.verification_status = 'not_submitted' AND NEW.verification_status = 'pending') THEN
                NULL;
            -- Allow self-deactivation or scheduling deletion
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

CREATE TRIGGER enforce_profile_security
    BEFORE UPDATE OF verification_status, profile_status ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.check_profile_status_safety();


-- ==========================================
-- SECURE INTERACTION RPC FUNCTIONS
-- ==========================================

-- 1. SEND KNOCK
CREATE OR REPLACE FUNCTION public.send_knock(target_user_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_sender_id UUID;
    v_sender_gender TEXT;
    v_target_gender TEXT;
    v_sender_status TEXT;
    v_target_status TEXT;
    v_is_premium BOOLEAN := false;
    v_daily_sent INTEGER := 0;
    v_knock_id UUID;
BEGIN
    -- Authenticate caller
    v_sender_id := auth.uid();
    IF v_sender_id IS NULL THEN
        RAISE EXCEPTION 'Unauthenticated';
    END IF;
    
    IF v_sender_id = target_user_id THEN
        RAISE EXCEPTION 'Cannot knock yourself';
    END IF;

    -- Fetch sender & target info
    SELECT gender, profile_status INTO v_sender_gender, v_sender_status FROM public.profiles WHERE id = v_sender_id;
    SELECT gender, profile_status INTO v_target_gender, v_target_status FROM public.profiles WHERE id = target_user_id;

    IF v_sender_status <> 'active' THEN
        RAISE EXCEPTION 'Sender profile must be active and approved';
    END IF;
    IF v_target_status <> 'active' THEN
        RAISE EXCEPTION 'Target profile is not active';
    END IF;

    -- Marriage platforms show opposite gender only
    IF v_sender_gender = v_target_gender THEN
        RAISE EXCEPTION 'Gender compatibility mismatch';
    END IF;

    -- Check blocking
    IF EXISTS(SELECT 1 FROM public.blocks WHERE (blocker_id = v_sender_id AND blocked_id = target_user_id) OR (blocker_id = target_user_id AND blocked_id = v_sender_id)) THEN
        RAISE EXCEPTION 'Interaction blocked';
    END IF;

    -- Check active subscription entitlement
    IF EXISTS(SELECT 1 FROM public.subscriptions WHERE user_id = v_sender_id AND status = 'active' AND entitlement = 'premium') THEN
        v_is_premium := true;
    END IF;

    -- Enforce daily limit for free tier (20 knocks)
    IF NOT v_is_premium THEN
        -- Get current usage or initialize
        INSERT INTO public.daily_usage (user_id, usage_date, knocks_sent)
        VALUES (v_sender_id, CURRENT_DATE, 0)
        ON CONFLICT (user_id, usage_date) DO NOTHING;

        SELECT knocks_sent INTO v_daily_sent FROM public.daily_usage WHERE user_id = v_sender_id AND usage_date = CURRENT_DATE;
        
        IF v_daily_sent >= 20 THEN
            RETURN jsonb_build_object('success', false, 'error', 'DAILY_LIMIT_EXCEEDED', 'limit', 20, 'sent', v_daily_sent);
        END IF;
    END IF;

    -- Insert knock (atomically)
    INSERT INTO public.knocks (sender_id, receiver_id, status, expires_at)
    VALUES (v_sender_id, target_user_id, 'pending', now() + INTERVAL '7 days')
    RETURNING id INTO v_knock_id;

    -- Increment usage
    IF NOT v_is_premium THEN
        UPDATE public.daily_usage 
        SET knocks_sent = knocks_sent + 1 
        WHERE user_id = v_sender_id AND usage_date = CURRENT_DATE;
        v_daily_sent := v_daily_sent + 1;
    END IF;

    -- Trigger In-App notification
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
        target_user_id,
        'knock_received',
        'New Knock Received',
        'Someone showed interest in your profile! Tap to view.',
        jsonb_build_object('knock_id', v_knock_id, 'sender_id', v_sender_id)
    );

    RETURN jsonb_build_object('success', true, 'knock_id', v_knock_id, 'premium', v_is_premium, 'remaining', CASE WHEN v_is_premium THEN -1 ELSE (20 - v_daily_sent) END);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. APPROVE KNOCK
CREATE OR REPLACE FUNCTION public.approve_knock(knock_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_receiver_id UUID;
    v_sender_id UUID;
    v_conv_id UUID;
BEGIN
    v_receiver_id := auth.uid();
    IF v_receiver_id IS NULL THEN
        RAISE EXCEPTION 'Unauthenticated';
    END IF;

    -- Fetch and lock knock
    SELECT sender_id INTO v_sender_id FROM public.knocks 
    WHERE id = knock_id AND receiver_id = v_receiver_id AND status = 'pending' 
    FOR UPDATE;

    IF v_sender_id IS NULL THEN
        RAISE EXCEPTION 'Knock not found or already processed';
    END IF;

    -- Check blocking
    IF EXISTS(SELECT 1 FROM public.blocks WHERE (blocker_id = v_sender_id AND blocked_id = v_receiver_id) OR (blocker_id = v_receiver_id AND blocked_id = v_sender_id)) THEN
        RAISE EXCEPTION 'Blocked interaction';
    END IF;

    -- Update knock status
    UPDATE public.knocks SET status = 'approved' WHERE id = knock_id;

    -- Create or retrieve conversation
    SELECT c.id INTO v_conv_id FROM public.conversations c
    JOIN public.conversation_members m1 ON c.id = m1.conversation_id
    JOIN public.conversation_members m2 ON c.id = m2.conversation_id
    WHERE m1.user_id = v_sender_id AND m2.user_id = v_receiver_id;

    IF v_conv_id IS NULL THEN
        INSERT INTO public.conversations (last_message_preview, last_message_at)
        VALUES ('Knock accepted! Start your conversation here.', now())
        RETURNING id INTO v_conv_id;

        INSERT INTO public.conversation_members (conversation_id, user_id) VALUES (v_conv_id, v_sender_id);
        INSERT INTO public.conversation_members (conversation_id, user_id) VALUES (v_conv_id, v_receiver_id);
    END IF;

    -- Notify sender
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
        v_sender_id,
        'knock_approved',
        'Knock Approved',
        'Your Knock was accepted! You can now message each other.',
        jsonb_build_object('conversation_id', v_conv_id, 'partner_id', v_receiver_id)
    );

    RETURN jsonb_build_object('success', true, 'conversation_id', v_conv_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. CREATE CHAT REQUEST
CREATE OR REPLACE FUNCTION public.create_chat_request(target_user_id UUID, introduction_text TEXT)
RETURNS JSONB AS $$
DECLARE
    v_sender_id UUID;
    v_sender_status TEXT;
    v_target_status TEXT;
    v_is_premium BOOLEAN := false;
    v_daily_sent INTEGER := 0;
    v_request_id UUID;
BEGIN
    v_sender_id := auth.uid();
    IF v_sender_id IS NULL THEN
        RAISE EXCEPTION 'Unauthenticated';
    END IF;

    IF char_length(introduction_text) > 300 THEN
        RAISE EXCEPTION 'Introduction exceeds 300 characters';
    END IF;

    SELECT profile_status INTO v_sender_status FROM public.profiles WHERE id = v_sender_id;
    SELECT profile_status INTO v_target_status FROM public.profiles WHERE id = target_user_id;

    IF v_sender_status <> 'active' OR v_target_status <> 'active' THEN
        RAISE EXCEPTION 'Both profiles must be active';
    END IF;

    -- Check blocking
    IF EXISTS(SELECT 1 FROM public.blocks WHERE (blocker_id = v_sender_id AND blocked_id = target_user_id) OR (blocker_id = target_user_id AND blocked_id = v_sender_id)) THEN
        RAISE EXCEPTION 'Blocked interaction';
    END IF;

    -- Check subscription
    IF EXISTS(SELECT 1 FROM public.subscriptions WHERE user_id = v_sender_id AND status = 'active' AND entitlement = 'premium') THEN
        v_is_premium := true;
    END IF;

    -- Enforce limit of 5 requests/day
    IF NOT v_is_premium THEN
        INSERT INTO public.daily_usage (user_id, usage_date, chat_requests_sent)
        VALUES (v_sender_id, CURRENT_DATE, 0)
        ON CONFLICT (user_id, usage_date) DO NOTHING;

        SELECT chat_requests_sent INTO v_daily_sent FROM public.daily_usage WHERE user_id = v_sender_id AND usage_date = CURRENT_DATE;

        IF v_daily_sent >= 5 THEN
            RETURN jsonb_build_object('success', false, 'error', 'DAILY_LIMIT_EXCEEDED', 'limit', 5, 'sent', v_daily_sent);
        END IF;
    END IF;

    -- Insert Request
    INSERT INTO public.chat_requests (sender_id, receiver_id, introduction, status, expires_at)
    VALUES (v_sender_id, target_user_id, introduction_text, 'pending', now() + INTERVAL '7 days')
    RETURNING id INTO v_request_id;

    -- Update usage
    IF NOT v_is_premium THEN
        UPDATE public.daily_usage 
        SET chat_requests_sent = chat_requests_sent + 1 
        WHERE user_id = v_sender_id AND usage_date = CURRENT_DATE;
        v_daily_sent := v_daily_sent + 1;
    END IF;

    -- Notify target
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
        target_user_id,
        'chat_request_received',
        'New Chat Request',
        'Someone requested to chat with you directly. Check details.',
        jsonb_build_object('request_id', v_request_id, 'sender_id', v_sender_id)
    );

    RETURN jsonb_build_object('success', true, 'request_id', v_request_id, 'remaining', CASE WHEN v_is_premium THEN -1 ELSE (5 - v_daily_sent) END);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ==========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==========================================

-- Enable RLS globally
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.private_user_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_optional_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_traits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_filters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_rule_acceptances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.knocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- 1. Profiles Policies
CREATE POLICY "Users can view opposite gender active profiles" ON public.profiles
    FOR SELECT USING (
        id = auth.uid() 
        OR (
            profile_status = 'active'
            AND gender <> (SELECT gender FROM public.profiles WHERE id = auth.uid())
            AND NOT EXISTS (SELECT 1 FROM public.blocks WHERE blocker_id = auth.uid() AND blocked_id = profiles.id)
            AND NOT EXISTS (SELECT 1 FROM public.blocks WHERE blocker_id = profiles.id AND blocked_id = auth.uid())
        )
    );

CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- 2. Private User Data Policies
CREATE POLICY "Users can only read/write their own private user data" ON public.private_user_data
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 3. Profile Images Policies
CREATE POLICY "Users can read approved profile images of the opposite gender" ON public.profile_images
    FOR SELECT USING (
        user_id = auth.uid()
        OR (
            moderation_status = 'approved'
            AND EXISTS (
                SELECT 1 FROM public.profiles 
                WHERE id = profile_images.user_id 
                AND profile_status = 'active'
                AND gender <> (SELECT gender FROM public.profiles WHERE id = auth.uid())
            )
        )
    );

CREATE POLICY "Users can manage their own profile images" ON public.profile_images
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 4. Messages Policies
CREATE POLICY "Members can read conversation messages" ON public.messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.conversation_members 
            WHERE conversation_id = messages.conversation_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Members can insert messages in active conversations" ON public.messages
    FOR INSERT WITH CHECK (
        sender_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.conversation_members 
            WHERE conversation_id = messages.conversation_id AND user_id = auth.uid()
        )
        AND NOT EXISTS (
            -- Check if other member blocked sender
            SELECT 1 FROM public.blocks b
            JOIN public.conversation_members m ON m.user_id = b.blocker_id
            WHERE m.conversation_id = messages.conversation_id AND b.blocked_id = auth.uid()
        )
    );

-- 5. Notifications Policies
CREATE POLICY "Users can view and edit their own notifications" ON public.notifications
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 6. Device Tokens Policies
CREATE POLICY "Users can manage their device tokens" ON public.device_tokens
    FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 7. Blocks Policies
CREATE POLICY "Users can manage their blocks" ON public.blocks
    FOR ALL USING (blocker_id = auth.uid()) WITH CHECK (blocker_id = auth.uid());

-- 8. Subscriptions Policies
CREATE POLICY "Users can read their own subscriptions" ON public.subscriptions
    FOR SELECT USING (user_id = auth.uid());
