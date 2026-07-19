-- Push each authenticated user's allowance changes to the app immediately.
ALTER TABLE public.daily_usage REPLICA IDENTITY FULL;
ALTER TABLE public.daily_usage ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read their own daily usage"
ON public.daily_usage;

CREATE POLICY "Users can read their own daily usage"
ON public.daily_usage
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'daily_usage'
    ) THEN
        ALTER PUBLICATION supabase_realtime
        ADD TABLE public.daily_usage;
    END IF;
END;
$$;
