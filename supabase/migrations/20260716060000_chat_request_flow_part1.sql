-- Part 1: create/read chat requests before they become conversations.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM pg_policies
         WHERE schemaname = 'public'
           AND tablename = 'chat_requests'
           AND policyname = 'Members can read their own chat requests'
    ) THEN
        CREATE POLICY "Members can read their own chat requests"
        ON public.chat_requests
        FOR SELECT
        USING (sender_id = auth.uid() OR receiver_id = auth.uid());
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_chat_request(
    target_user_id UUID,
    introduction_text TEXT
)
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

    IF v_sender_id = target_user_id THEN
        RAISE EXCEPTION 'Cannot request yourself';
    END IF;

    IF char_length(trim(introduction_text)) = 0 OR char_length(introduction_text) > 300 THEN
        RAISE EXCEPTION 'Introduction must be between 1 and 300 characters';
    END IF;

    SELECT profile_status INTO v_sender_status
      FROM public.profiles
     WHERE id = v_sender_id;

    SELECT profile_status INTO v_target_status
      FROM public.profiles
     WHERE id = target_user_id;

    IF v_sender_status <> 'active' OR v_target_status <> 'active' THEN
        RAISE EXCEPTION 'Both profiles must be active';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.blocks
         WHERE (blocker_id = v_sender_id AND blocked_id = target_user_id)
            OR (blocker_id = target_user_id AND blocked_id = v_sender_id)
    ) THEN
        RAISE EXCEPTION 'Blocked interaction';
    END IF;

    SELECT id INTO v_request_id
      FROM public.chat_requests
     WHERE sender_id = v_sender_id
       AND receiver_id = target_user_id
       AND status = 'pending'
     LIMIT 1;

    IF v_request_id IS NOT NULL THEN
        RETURN jsonb_build_object(
            'success', true,
            'request_id', v_request_id,
            'duplicate', true
        );
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.subscriptions
         WHERE user_id = v_sender_id
           AND status = 'active'
           AND entitlement = 'premium'
    ) THEN
        v_is_premium := true;
    END IF;

    IF NOT v_is_premium THEN
        INSERT INTO public.daily_usage (user_id, usage_date, chat_requests_sent)
        VALUES (v_sender_id, CURRENT_DATE, 0)
        ON CONFLICT (user_id, usage_date) DO NOTHING;

        SELECT chat_requests_sent INTO v_daily_sent
          FROM public.daily_usage
         WHERE user_id = v_sender_id
           AND usage_date = CURRENT_DATE;

        IF v_daily_sent >= 5 THEN
            RETURN jsonb_build_object(
                'success', false,
                'error', 'DAILY_LIMIT_EXCEEDED',
                'limit', 5,
                'sent', v_daily_sent
            );
        END IF;
    END IF;

    INSERT INTO public.chat_requests (
        sender_id,
        receiver_id,
        introduction,
        status,
        expires_at
    )
    VALUES (
        v_sender_id,
        target_user_id,
        introduction_text,
        'pending',
        now() + INTERVAL '7 days'
    )
    RETURNING id INTO v_request_id;

    IF NOT v_is_premium THEN
        UPDATE public.daily_usage
           SET chat_requests_sent = chat_requests_sent + 1
         WHERE user_id = v_sender_id
           AND usage_date = CURRENT_DATE;
        v_daily_sent := v_daily_sent + 1;
    END IF;

    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
        target_user_id,
        'chat_request_received',
        'New Chat Request',
        'Someone requested to chat with you directly. Check Messages.',
        jsonb_build_object('request_id', v_request_id, 'sender_id', v_sender_id)
    );

    RETURN jsonb_build_object(
        'success', true,
        'request_id', v_request_id,
        'remaining', CASE WHEN v_is_premium THEN -1 ELSE (5 - v_daily_sent) END
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
