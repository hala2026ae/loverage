-- Active-chat messages share the same five-action daily chat allowance.
CREATE OR REPLACE FUNCTION public.send_message(conversation UUID, body TEXT)
RETURNS JSONB AS $$
DECLARE
    v_sender UUID := auth.uid();
    v_premium BOOLEAN := false;
    v_existing INTEGER := 0;
    v_used INTEGER;
    v_message UUID;
BEGIN
    IF v_sender IS NULL THEN RAISE EXCEPTION 'Unauthenticated'; END IF;
    IF char_length(trim(body)) = 0 OR char_length(body) > 2000 THEN
        RAISE EXCEPTION 'Message must be between 1 and 2000 characters';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM public.conversations
        WHERE id = conversation
          AND (participant_a = v_sender OR participant_b = v_sender)
    ) THEN RAISE EXCEPTION 'Conversation not found'; END IF;

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

    INSERT INTO public.messages (
        conversation_id, sender_id, body, delivered_at
    ) VALUES (conversation, v_sender, trim(body), now())
    RETURNING id INTO v_message;

    UPDATE public.conversations
    SET last_message_preview = trim(body),
        last_message_at = now(),
        updated_at = now()
    WHERE id = conversation;

    RETURN jsonb_build_object(
        'success', true, 'message_id', v_message, 'consumed', true,
        'premium', v_premium,
        'remaining', CASE WHEN v_premium THEN -1 ELSE 5 - v_used END
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.send_message(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.send_message(UUID, TEXT) TO authenticated;
