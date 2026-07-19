-- Atomically consume one of the 20 daily knocks only for a new request.
CREATE OR REPLACE FUNCTION public.send_knock(target_user_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_sender UUID := auth.uid();
    v_sender_gender TEXT;
    v_target_gender TEXT;
    v_sender_status TEXT;
    v_target_status TEXT;
    v_premium BOOLEAN := false;
    v_existing INTEGER := 0;
    v_used INTEGER;
    v_knock UUID;
BEGIN
    IF v_sender IS NULL THEN RAISE EXCEPTION 'Unauthenticated'; END IF;
    IF v_sender = target_user_id THEN RAISE EXCEPTION 'Cannot knock yourself'; END IF;

    SELECT gender, profile_status INTO v_sender_gender, v_sender_status
    FROM public.profiles WHERE id = v_sender;
    SELECT gender, profile_status INTO v_target_gender, v_target_status
    FROM public.profiles WHERE id = target_user_id;

    IF v_sender_status <> 'active' THEN
        RAISE EXCEPTION 'Sender profile must be active';
    END IF;
    IF v_target_status <> 'active' THEN
        RAISE EXCEPTION 'Target profile is not active';
    END IF;
    IF v_sender_gender = v_target_gender THEN
        RAISE EXCEPTION 'Gender compatibility mismatch';
    END IF;
    IF EXISTS (
        SELECT 1 FROM public.blocks
        WHERE (blocker_id = v_sender AND blocked_id = target_user_id)
           OR (blocker_id = target_user_id AND blocked_id = v_sender)
    ) THEN RAISE EXCEPTION 'Interaction blocked'; END IF;

    SELECT id INTO v_knock FROM public.knocks
    WHERE sender_id = v_sender AND receiver_id = target_user_id
      AND status = 'pending' LIMIT 1;
    IF v_knock IS NOT NULL THEN
        RETURN jsonb_build_object(
            'success', true, 'knock_id', v_knock,
            'duplicate', true, 'consumed', false
        );
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM public.subscriptions
        WHERE user_id = v_sender AND status = 'active'
          AND entitlement = 'premium'
          AND current_period_end > now()
    ) INTO v_premium;

    IF NOT v_premium THEN
        SELECT count(*)::INTEGER INTO v_existing FROM public.knocks
        WHERE sender_id = v_sender
          AND created_at >= date_trunc('day', now());
        INSERT INTO public.daily_usage AS usage (
            user_id, usage_date, knocks_sent, chat_requests_sent
        ) VALUES (v_sender, CURRENT_DATE, v_existing, 0)
        ON CONFLICT (user_id, usage_date) DO UPDATE
        SET knocks_sent = GREATEST(usage.knocks_sent, EXCLUDED.knocks_sent);

        INSERT INTO public.daily_usage AS usage (
            user_id, usage_date, knocks_sent, chat_requests_sent
        ) VALUES (v_sender, CURRENT_DATE, 1, 0)
        ON CONFLICT (user_id, usage_date) DO UPDATE
        SET knocks_sent = usage.knocks_sent + 1
        WHERE usage.knocks_sent < 20
        RETURNING knocks_sent INTO v_used;

        IF v_used IS NULL THEN
            SELECT COALESCE(knocks_sent, 20) INTO v_used
            FROM public.daily_usage
            WHERE user_id = v_sender AND usage_date = CURRENT_DATE;
            RETURN jsonb_build_object(
                'success', false, 'error', 'DAILY_LIMIT_EXCEEDED',
                'limit', 20, 'sent', COALESCE(v_used, 20), 'remaining', 0
            );
        END IF;
    END IF;

    INSERT INTO public.knocks (sender_id, receiver_id, status, expires_at)
    VALUES (v_sender, target_user_id, 'pending', now() + INTERVAL '7 days')
    RETURNING id INTO v_knock;

    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
        target_user_id, 'knock_received', 'New Knock Received',
        'Someone showed interest in your profile! Tap to view.',
        jsonb_build_object('knock_id', v_knock, 'sender_id', v_sender)
    );

    RETURN jsonb_build_object(
        'success', true, 'knock_id', v_knock, 'consumed', true,
        'premium', v_premium,
        'remaining', CASE WHEN v_premium THEN -1 ELSE 20 - v_used END
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.send_knock(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.send_knock(UUID) TO authenticated;
