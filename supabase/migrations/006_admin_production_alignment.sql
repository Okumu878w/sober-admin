-- 006_admin_production_alignment.sql
-- Align the admin panel with the supplied Sober Connect schema.
-- This migration is intentionally additive and preserves Android-facing columns.

-- Moderation fields/workflow
alter table public.content_reports add column if not exists reviewed_at timestamptz;
alter table public.content_reports add column if not exists moderator_note text;
do $$
begin
  if exists (select 1 from pg_constraint where conname = 'content_reports_status_check') then
    alter table public.content_reports drop constraint content_reports_status_check;
  end if;
  alter table public.content_reports
    add constraint content_reports_status_check
    check (status in ('OPEN','REVIEWED','DISMISSED','ESCALATED'));
exception when duplicate_object then null;
end $$;

-- Resource type compatibility for admin-managed uploaded content.
do $$
begin
  if exists (select 1 from pg_constraint where conname = 'resources_resource_type_check') then
    alter table public.resources drop constraint resources_resource_type_check;
  end if;
  alter table public.resources
    add constraint resources_resource_type_check
    check (resource_type in ('ARTICLE','VIDEO','PODCAST','HELPLINE','SERVICE','DOCUMENT','AUDIO','OTHER'));
exception when duplicate_object then null;
end $$;

-- Groups keep meeting credentials in the existing protected table.
alter table public.virtual_support_groups add column if not exists status text not null default 'DRAFT';
alter table public.virtual_support_groups add column if not exists meeting_instructions text;

-- Rebuild the Android/admin group view with the administrative fields.
drop view if exists public.v_virtual_groups;
create view public.v_virtual_groups with (security_invoker = true) as
select
  g.id, g.name, g.description, g.scheduled_time, g.recurrence,
  g.max_participants, g.member_count, g.is_active, g.created_at,
  g.host_id, hp.full_name as host_name,
  d.meeting_link, d.meeting_id, d.meeting_password,
  g.status, g.meeting_instructions,
  now() as updated_at,
  exists (
    select 1 from public.group_members m
    where m.group_id = g.id and m.user_id = (select auth.uid())
  ) as is_member
from public.virtual_support_groups g
left join public.profiles hp on hp.id = g.host_id
left join public.group_meeting_details d on d.group_id = g.id;
grant select on public.v_virtual_groups to authenticated;

-- Replace legacy broad staff policies. RLS policies are ORed, so leaving them
-- in place would allow legacy MODERATOR/ADMIN profiles to bypass admin roles.
drop policy if exists "events read" on public.events;
drop policy if exists "events staff insert" on public.events;
drop policy if exists "events staff update" on public.events;
drop policy if exists "events staff delete" on public.events;
drop policy if exists "events_public_published_read" on public.events;
drop policy if exists "events_staff_manage" on public.events;

create policy "events_published_read" on public.events
for select to anon, authenticated
using (status = 'PUBLISHED');

create policy "events_admin_manage" on public.events
for all to authenticated
using (public.has_admin_role(array['SUPER_ADMIN','ADMIN','EVENTS_ADMIN']))
with check (public.has_admin_role(array['SUPER_ADMIN','ADMIN','EVENTS_ADMIN']));

drop policy if exists "resources read" on public.resources;
drop policy if exists "resources staff read all" on public.resources;
drop policy if exists "resources staff insert" on public.resources;
drop policy if exists "resources staff update" on public.resources;
drop policy if exists "resources staff delete" on public.resources;
drop policy if exists "resources_public_active_read" on public.resources;
drop policy if exists "resources_content_manage" on public.resources;

create policy "resources_published_read" on public.resources
for select to anon, authenticated
using (is_active = true and status = 'PUBLISHED');

create policy "resources_content_admin_manage" on public.resources
for all to authenticated
using (public.has_admin_role(array['SUPER_ADMIN','ADMIN','CONTENT_ADMIN']))
with check (public.has_admin_role(array['SUPER_ADMIN','ADMIN','CONTENT_ADMIN']));

drop policy if exists "groups read" on public.virtual_support_groups;
drop policy if exists "groups staff insert" on public.virtual_support_groups;
drop policy if exists "groups staff update" on public.virtual_support_groups;
drop policy if exists "groups staff delete" on public.virtual_support_groups;
drop policy if exists "groups_public_active_read" on public.virtual_support_groups;
drop policy if exists "groups_events_manage" on public.virtual_support_groups;

create policy "groups_published_read" on public.virtual_support_groups
for select to authenticated
using (is_active = true and status = 'PUBLISHED');

create policy "groups_events_admin_manage" on public.virtual_support_groups
for all to authenticated
using (public.has_admin_role(array['SUPER_ADMIN','ADMIN','EVENTS_ADMIN']))
with check (public.has_admin_role(array['SUPER_ADMIN','ADMIN','EVENTS_ADMIN']));

drop policy if exists "meeting details staff write" on public.group_meeting_details;
create policy "meeting details events_admin_write" on public.group_meeting_details
for all to authenticated
using (public.has_admin_role(array['SUPER_ADMIN','ADMIN','EVENTS_ADMIN']))
with check (public.has_admin_role(array['SUPER_ADMIN','ADMIN','EVENTS_ADMIN']));

-- Moderation is deliberately limited to moderation/admin roles.
drop policy if exists "reports staff read" on public.content_reports;
drop policy if exists "reports staff update" on public.content_reports;
create policy "reports_moderator_read" on public.content_reports
for select to authenticated
using (public.has_admin_role(array['SUPER_ADMIN','ADMIN','MODERATOR']));

create policy "reports_moderator_update" on public.content_reports
for update to authenticated
using (public.has_admin_role(array['SUPER_ADMIN','ADMIN','MODERATOR']))
with check (public.has_admin_role(array['SUPER_ADMIN','ADMIN','MODERATOR']));

grant select, insert on public.content_reports to authenticated;
grant update (status, reviewed_at, moderator_note) on public.content_reports to authenticated;

-- Support and audit tables need explicit privileges because the base schema
-- revokes broad public-schema privileges.
grant select on public.audit_logs to authenticated;
grant select on public.support_resources to anon, authenticated;
grant insert, update, delete on public.support_resources to authenticated;

-- Admin users can only be listed/changed by SUPER_ADMIN; self-read remains.
grant select on public.admin_profiles to authenticated;
grant update (display_name, role, status, last_activity_at) on public.admin_profiles to authenticated;

-- Existing group view/table privileges.
grant select, insert, update, delete on public.virtual_support_groups to authenticated;
grant select, insert, update, delete on public.group_meeting_details to authenticated;

-- Storage: use a dedicated public bucket for resources that are explicitly
-- published to the Android app. This does not make unrelated buckets public.
update storage.buckets set public = true where id = 'sober-resources';

drop policy if exists "sober_resources_authenticated_read" on storage.objects;
create policy "sober_resources_admin_read" on storage.objects
for select to authenticated
using (bucket_id = 'sober-resources' and public.is_admin());

-- Existing insert/update/delete policies remain role restricted.

-- Recreate the report queue view with the fields used by the admin UI.
drop view if exists public.v_open_reports;
create view public.v_open_reports with (security_invoker = true) as
select
  r.id as report_id,
  r.created_at,
  r.reason,
  r.status,
  r.reviewed_at,
  r.moderator_note,
  r.post_id,
  p.title as post_title,
  p.content as post_content,
  p.is_active as post_active,
  r.comment_id,
  c.content as comment_content,
  c.is_active as comment_active,
  coalesce(p.author_id, c.author_id) as author_id,
  pr.full_name as author_name,
  (
    select count(*) from public.content_reports x
    where x.status = 'OPEN'
      and x.post_id is not distinct from r.post_id
      and x.comment_id is not distinct from r.comment_id
  ) as open_reports_for_target
from public.content_reports r
left join public.forum_posts p on p.id = r.post_id
left join public.comments c on c.id = r.comment_id
left join public.profiles pr on pr.id = coalesce(p.author_id, c.author_id)
where r.status = 'OPEN'
order by r.created_at;
grant select on public.v_open_reports to authenticated;

-- Update the resolve RPC so it can be called by the admin moderation UI.
grant execute on function public.resolve_report(uuid,text) to authenticated;

-- Make the moderation RPC use the new admin RBAC instead of legacy profiles.role.
create or replace function public.resolve_report(p_report_id uuid, p_action text)
returns void language plpgsql security definer set search_path = '' as $$
declare v public.content_reports%rowtype;
begin
  if not public.has_admin_role(array['SUPER_ADMIN','ADMIN','MODERATOR']) then
    raise exception 'Not allowed';
  end if;
  if p_action not in ('HIDE','DISMISS') then
    raise exception 'Unknown action';
  end if;

  select * into v from public.content_reports where id = p_report_id;
  if not found then raise exception 'Report not found'; end if;

  if p_action = 'HIDE' then
    if v.post_id is not null then
      update public.forum_posts set is_active = false, is_moderated = true where id = v.post_id;
    end if;
    if v.comment_id is not null then
      update public.comments set is_active = false where id = v.comment_id;
    end if;
    update public.content_reports set status='REVIEWED', reviewed_at=now()
    where status='OPEN'
      and post_id is not distinct from v.post_id
      and comment_id is not distinct from v.comment_id;
  else
    if v.post_id is not null then
      update public.forum_posts set is_active = true, is_moderated = true where id = v.post_id;
    end if;
    if v.comment_id is not null then
      update public.comments set is_active = true where id = v.comment_id;
    end if;
    update public.content_reports set status='DISMISSED', reviewed_at=now()
    where status='OPEN'
      and post_id is not distinct from v.post_id
      and comment_id is not distinct from v.comment_id;
  end if;
end $$;
grant execute on function public.resolve_report(uuid,text) to authenticated;
