-- RLS for shared application content. Policies intentionally use backend role checks.

alter table if exists public.events enable row level security;
drop policy if exists "events_public_published_read" on public.events;
drop policy if exists "events_staff_manage" on public.events;
create policy "events_public_published_read" on public.events for select to anon,authenticated using (status='PUBLISHED');
create policy "events_staff_manage" on public.events for all to authenticated using (public.has_admin_role(array['SUPER_ADMIN','ADMIN','EVENTS_ADMIN'])) with check (public.has_admin_role(array['SUPER_ADMIN','ADMIN','EVENTS_ADMIN']));

alter table if exists public.resources enable row level security;
drop policy if exists "resources_public_active_read" on public.resources;
drop policy if exists "resources_content_manage" on public.resources;
create policy "resources_public_active_read" on public.resources for select to anon,authenticated using (is_active=true and status='PUBLISHED');
create policy "resources_content_manage" on public.resources for all to authenticated using (public.has_admin_role(array['SUPER_ADMIN','ADMIN','CONTENT_ADMIN'])) with check (public.has_admin_role(array['SUPER_ADMIN','ADMIN','CONTENT_ADMIN']));

alter table if exists public.virtual_support_groups enable row level security;
drop policy if exists "groups_public_active_read" on public.virtual_support_groups;
drop policy if exists "groups_events_manage" on public.virtual_support_groups;
create policy "groups_public_active_read" on public.virtual_support_groups for select to anon,authenticated using (is_active=true and status='PUBLISHED');
create policy "groups_events_manage" on public.virtual_support_groups for all to authenticated using (public.has_admin_role(array['SUPER_ADMIN','ADMIN','EVENTS_ADMIN'])) with check (public.has_admin_role(array['SUPER_ADMIN','ADMIN','EVENTS_ADMIN']));

-- Storage bucket. Keep it private by default. Use signed URLs for private content.
insert into storage.buckets (id,name,public) values ('sober-resources','sober-resources',false) on conflict (id) do nothing;
drop policy if exists "sober_resources_admin_insert" on storage.objects;
drop policy if exists "sober_resources_admin_update" on storage.objects;
drop policy if exists "sober_resources_admin_delete" on storage.objects;
drop policy if exists "sober_resources_authenticated_read" on storage.objects;
create policy "sober_resources_admin_insert" on storage.objects for insert to authenticated with check (bucket_id='sober-resources' and public.has_admin_role(array['SUPER_ADMIN','ADMIN','CONTENT_ADMIN']));
create policy "sober_resources_admin_update" on storage.objects for update to authenticated using (bucket_id='sober-resources' and public.has_admin_role(array['SUPER_ADMIN','ADMIN','CONTENT_ADMIN'])) with check (bucket_id='sober-resources' and public.has_admin_role(array['SUPER_ADMIN','ADMIN','CONTENT_ADMIN']));
create policy "sober_resources_admin_delete" on storage.objects for delete to authenticated using (bucket_id='sober-resources' and public.has_admin_role(array['SUPER_ADMIN','ADMIN','CONTENT_ADMIN']));
create policy "sober_resources_authenticated_read" on storage.objects for select to authenticated using (bucket_id='sober-resources' and public.is_admin());
