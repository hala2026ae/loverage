-- Track message delivery/read states for chat bubbles.
ALTER TABLE public.messages
ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ;

UPDATE public.messages
   SET delivered_at = created_at
 WHERE delivered_at IS NULL;

CREATE OR REPLACE FUNCTION public.send_message(conversation UUID, body TEXT)
RETURNS JSONB AS $$
DECLARE
    v_sender_id UUID;
    v_message_id UUID;
BEGIN
    v_sender_id := auth.uid();
    IF v_sender_id IS NULL THEN
        RAISE EXCEPTION 'Unauthenticated';
    END IF;

    IF char_length(body) = 0 OR char_length(body) > 2000 THEN
        RAISE EXCEPTION 'Message must be between 1 and 2000 characters';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM public.conversations
         WHERE id = conversation
           AND (participant_a = v_sender_id OR participant_b = v_sender_id)
    ) THEN
        RAISE EXCEPTION 'Conversation not found';
    END IF;

    INSERT INTO public.messages (
        conversation_id,
        sender_id,
        body,
        delivered_at
    )
    VALUES (
        conversation,
        v_sender_id,
        body,
        now()
    )
    RETURNING id INTO v_message_id;

    UPDATE public.conversations
       SET last_message_preview = body,
           last_message_at = now(),
           updated_at = now()
     WHERE id = conversation;

    RETURN jsonb_build_object('success', true, 'message_id', v_message_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.mark_conversation_messages_seen(conversation UUID)
RETURNS JSONB AS $$
DECLARE
    v_reader_id UUID;
BEGIN
    v_reader_id := auth.uid();
    IF v_reader_id IS NULL THEN
        RAISE EXCEPTION 'Unauthenticated';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM public.conversations
         WHERE id = conversation
           AND (participant_a = v_reader_id OR participant_b = v_reader_id)
    ) THEN
        RAISE EXCEPTION 'Conversation not found';
    END IF;

    UPDATE public.messages
       SET delivered_at = COALESCE(delivered_at, now()),
           read_at = COALESCE(read_at, now())
     WHERE conversation_id = conversation
       AND sender_id <> v_reader_id
       AND read_at IS NULL;

    RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
