-- Server-authoritative daily usage counters for the app allowance card.
CREATE OR REPLACE FUNCTION public.get_my_daily_usage()
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_knocks INTEGER := 0;
    v_chats INTEGER := 0;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Unauthenticated';
    END IF;

    SELECT knocks_sent, chat_requests_sent
      INTO v_knocks, v_chats
      FROM public.daily_usage
     WHERE user_id = v_user_id
       AND usage_date = CURRENT_DATE;

    SELECT GREATEST(
        COALESCE(v_knocks, 0),
        (SELECT count(*)::INTEGER FROM public.knocks
         WHERE sender_id = v_user_id
           AND created_at >= date_trunc('day', now()))
    ) INTO v_knocks;
    SELECT GREATEST(
        COALESCE(v_chats, 0),
        (SELECT count(*)::INTEGER FROM public.chat_requests
         WHERE sender_id = v_user_id
           AND created_at >= date_trunc('day', now()))
        + (SELECT count(*)::INTEGER FROM public.messages
           WHERE sender_id = v_user_id
             AND created_at >= date_trunc('day', now()))
    ) INTO v_chats;

    INSERT INTO public.daily_usage AS usage (
        user_id, usage_date, knocks_sent, chat_requests_sent
    ) VALUES (v_user_id, CURRENT_DATE, v_knocks, v_chats)
    ON CONFLICT (user_id, usage_date) DO UPDATE SET
        knocks_sent = GREATEST(usage.knocks_sent, EXCLUDED.knocks_sent),
        chat_requests_sent = GREATEST(
            usage.chat_requests_sent,
            EXCLUDED.chat_requests_sent
        );

    RETURN jsonb_build_object(
        'knocks_sent', COALESCE(v_knocks, 0),
        'chat_requests_sent', COALESCE(v_chats, 0),
        'knocks_remaining', GREATEST(20 - COALESCE(v_knocks, 0), 0),
        'chats_remaining', GREATEST(5 - COALESCE(v_chats, 0), 0),
        'usage_date', CURRENT_DATE,
        'knock_limit', 20,
        'chat_limit', 5
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.get_my_daily_usage() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_daily_usage() TO authenticated;
