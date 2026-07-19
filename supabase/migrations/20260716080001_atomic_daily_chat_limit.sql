-- Atomically consume one of the 5 daily chat requests only for a new request.
CREATE OR REPLACE FUNCTION public.create_chat_request(
    target_user_id UUID,
    introduction_text TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_sender UUID := auth.uid();
    v_sender_status TEXT;
    v_target_status TEXT;
    v_premium BOOLEAN := false;
    v_existing INTEGER := 0;
    v_used INTEGER;
    v_request UUID;
BEGIN
    IF v_sender IS NULL THEN RAISE EXCEPTION 'Unauthenticated'; END IF;
    IF v_sender = target_user_id THEN RAISE EXCEPTION 'Cannot request yourself'; END IF;
    IF char_length(trim(introduction_text)) = 0
       OR char_length(introduction_text) > 300 THEN
        RAISE EXCEPTION 'Introduction must be between 1 and 300 characters';
    END IF;

    SELECT profile_status INTO v_sender_status
    FROM public.profiles WHERE id = v_sender;
    SELECT profile_status INTO v_target_status
    FROM public.profiles WHERE id = target_user_id;
    IF v_sender_status <> 'active' OR v_target_status <> 'active' THEN
        RAISE EXCEPTION 'Both profiles must be active';
    END IF;
    IF EXISTS (
        SELECT 1 FROM public.blocks
        WHERE (blocker_id = v_sender AND blocked_id = target_user_id)
           OR (blocker_id = target_user_id AND blocked_id = v_sender)
    ) THEN RAISE EXCEPTION 'Blocked interaction'; END IF;

    SELECT id INTO v_request FROM public.chat_requests
    WHERE sender_id = v_sender AND receiver_id = target_user_id
      AND status = 'pending' LIMIT 1;
    IF v_request IS NOT NULL THEN
        RETURN jsonb_build_object(
            'success', true, 'request_id', v_request,
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
        SELECT
            (SELECT count(*)::INTEGER FROM public.chat_requests
             WHERE sender_id = v_sender
               AND created_at >= date_trunc('day', now()))
          + (SELECT count(*)::INTEGER FROM public.messages
             WHERE sender_id = v_sender
               AND created_at >= date_trunc('day', now()))
        INTO v_existing;
        INSERT INTO public.daily_usage AS usage (
            user_id, usage_date, knocks_sent, chat_requests_sent
        ) VALUES (v_sender, CURRENT_DATE, 0, v_existing)
        ON CONFLICT (user_id, usage_date) DO UPDATE
        SET chat_requests_sent = GREATEST(
            usage.chat_requests_sent,
            EXCLUDED.chat_requests_sent
        );

        INSERT INTO public.daily_usage AS usage (
            user_id, usage_date, knocks_sent, chat_requests_sent
        ) VALUES (v_sender, CURRENT_DATE, 0, 1)
        ON CONFLICT (user_id, usage_date) DO UPDATE
        SET chat_requests_sent = usage.chat_requests_sent + 1
        WHERE usage.chat_requests_sent < 5
        RETURNING chat_requests_sent INTO v_used;

        IF v_used IS NULL THEN
            SELECT COALESCE(chat_requests_sent, 5) INTO v_used
            FROM public.daily_usage
            WHERE user_id = v_sender AND usage_date = CURRENT_DATE;
            RETURN jsonb_build_object(
                'success', false, 'error', 'DAILY_LIMIT_EXCEEDED',
                'limit', 5, 'sent', COALESCE(v_used, 5), 'remaining', 0
            );
        END IF;
    END IF;

    INSERT INTO public.chat_requests (
        sender_id, receiver_id, introduction, status, expires_at
    ) VALUES (
        v_sender, target_user_id, trim(introduction_text),
        'pending', now() + INTERVAL '7 days'
    ) RETURNING id INTO v_request;

    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
        target_user_id, 'chat_request_received', 'New Chat Request',
        'Someone requested to chat with you directly. Check Messages.',
        jsonb_build_object('request_id', v_request, 'sender_id', v_sender)
    );

    RETURN jsonb_build_object(
        'success', true, 'request_id', v_request, 'consumed', true,
        'premium', v_premium,
        'remaining', CASE WHEN v_premium THEN -1 ELSE 5 - v_used END
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.create_chat_request(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_chat_request(UUID, TEXT) TO authenticated;
