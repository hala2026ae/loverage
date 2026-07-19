-- Members can display their own server-authoritative daily usage counters.
drop policy if exists "Users can read their own daily usage" on public.daily_usage;
create policy "Users can read their own daily usage"
on public.daily_usage for select
to authenticated
using (user_id = auth.uid());
