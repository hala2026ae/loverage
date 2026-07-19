-- Make duplicate pending knocks idempotent instead of surfacing a unique-index error.
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
    v_sender_id := auth.uid();
    IF v_sender_id IS NULL THEN
        RAISE EXCEPTION 'Unauthenticated';
    END IF;

    IF v_sender_id = target_user_id THEN
        RAISE EXCEPTION 'Cannot knock yourself';
    END IF;

    SELECT gender, profile_status
      INTO v_sender_gender, v_sender_status
      FROM public.profiles
     WHERE id = v_sender_id;

    SELECT gender, profile_status
      INTO v_target_gender, v_target_status
      FROM public.profiles
     WHERE id = target_user_id;

    IF v_sender_status <> 'active' THEN
        RAISE EXCEPTION 'Sender profile must be active and approved';
    END IF;

    IF v_target_status <> 'active' THEN
        RAISE EXCEPTION 'Target profile is not active';
    END IF;

    IF v_sender_gender = v_target_gender THEN
        RAISE EXCEPTION 'Gender compatibility mismatch';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM public.blocks
         WHERE (blocker_id = v_sender_id AND blocked_id = target_user_id)
            OR (blocker_id = target_user_id AND blocked_id = v_sender_id)
    ) THEN
        RAISE EXCEPTION 'Interaction blocked';
    END IF;

    SELECT id
      INTO v_knock_id
      FROM public.knocks
     WHERE sender_id = v_sender_id
       AND receiver_id = target_user_id
       AND status = 'pending'
     LIMIT 1;

    IF v_knock_id IS NOT NULL THEN
        RETURN jsonb_build_object(
            'success', true,
            'knock_id', v_knock_id,
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
        INSERT INTO public.daily_usage (user_id, usage_date, knocks_sent)
        VALUES (v_sender_id, CURRENT_DATE, 0)
        ON CONFLICT (user_id, usage_date) DO NOTHING;

        SELECT knocks_sent
          INTO v_daily_sent
          FROM public.daily_usage
         WHERE user_id = v_sender_id
           AND usage_date = CURRENT_DATE;

        IF v_daily_sent >= 20 THEN
            RETURN jsonb_build_object(
                'success', false,
                'error', 'DAILY_LIMIT_EXCEEDED',
                'limit', 20,
                'sent', v_daily_sent
            );
        END IF;
    END IF;

    INSERT INTO public.knocks (sender_id, receiver_id, status, expires_at)
    VALUES (v_sender_id, target_user_id, 'pending', now() + INTERVAL '7 days')
    RETURNING id INTO v_knock_id;

    IF NOT v_is_premium THEN
        UPDATE public.daily_usage
           SET knocks_sent = knocks_sent + 1
         WHERE user_id = v_sender_id
           AND usage_date = CURRENT_DATE;
        v_daily_sent := v_daily_sent + 1;
    END IF;

    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
        target_user_id,
        'knock_received',
        'New Knock Received',
        'Someone showed interest in your profile! Tap to view.',
        jsonb_build_object('knock_id', v_knock_id, 'sender_id', v_sender_id)
    );

    RETURN jsonb_build_object(
        'success', true,
        'knock_id', v_knock_id,
        'premium', v_is_premium,
        'remaining', CASE WHEN v_is_premium THEN -1 ELSE (20 - v_daily_sent) END
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
