-- Acknowledgement Force — content store
-- One row per user, holding the editable contract, quotes, goals, reflection.

create table if not exists public.contents (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  contract_md text        not null default '',
  quotes      jsonb       not null default '[]'::jsonb,  -- array of strings
  goals       jsonb       not null default '[]'::jsonb,  -- array of { id, label }
  reflection  text        not null default '',
  updated_at  timestamptz not null default now()
);

-- Row-level security: a user may only ever touch their own row.
alter table public.contents enable row level security;

drop policy if exists "contents_select_own" on public.contents;
create policy "contents_select_own"
  on public.contents for select
  using (auth.uid() = user_id);

drop policy if exists "contents_insert_own" on public.contents;
create policy "contents_insert_own"
  on public.contents for insert
  with check (auth.uid() = user_id);

drop policy if exists "contents_update_own" on public.contents;
create policy "contents_update_own"
  on public.contents for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Keep updated_at fresh on every write.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists contents_touch_updated_at on public.contents;
create trigger contents_touch_updated_at
  before update on public.contents
  for each row execute function public.touch_updated_at();

-- Seed a default contract for every new account.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.contents (user_id, contract_md, quotes, goals)
  values (
    new.id,
    $md$# Acknowledgement Force Daily Contract
**Date:** {{DATE}}
---
## I. Who I Am
I am building a high-leverage tech career. My success depends on **sustained performance**, not bursts of effort.
---
## II. Non-Negotiable Rules
1. **Protect sleep.** Without 7-8 hours, everything else collapses.
2. **Anxiety needs systems, not willpower.** Box breathing, 5-4-3-2-1 grounding, structured journaling.
3. **Execution beats planning.** Commits, deployments, and documentation are the only valid measures.
4. **One project at a time.** Finish before starting new.
5. **Burnout is not honourable.** I monitor energy and adjust load proactively.
---
## III. Daily Acknowledgement
**By opening this app, I acknowledge:**
- I have read and understood all principles above.
- I commit to executing with discipline and clarity.
- I measure progress by outputs, not hours or plans.
---
**I commit to this contract for today.**$md$,
    '["Execution beats planning. Commits, deployments, and documentation are the only valid measures."]'::jsonb,
    '[
      {"id":"brush-teeth","label":"Brush teeth (morning & night)"},
      {"id":"wash-face","label":"Wash face (morning & night)"},
      {"id":"leetcode","label":"LeetCode: 1 problem minimum"},
      {"id":"cold-message","label":"Send 1 cold message/email"},
      {"id":"gym","label":"Gym/30min physical activity"},
      {"id":"journal","label":"Journal: 5-10 minutes"},
      {"id":"read","label":"Read: 15-30 minutes"},
      {"id":"no-doomscroll","label":"No doomscrolling (sit in silence 5-10 min)"}
    ]'::jsonb
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
