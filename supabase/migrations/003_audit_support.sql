create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  admin_user uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id text,
  created_at timestamptz not null default now(),
  metadata jsonb
);
create index if not exists idx_audit_created_at on public.audit_logs(created_at desc);
create index if not exists idx_audit_action on public.audit_logs(action);
create index if not exists idx_audit_entity on public.audit_logs(entity_type,entity_id);
alter table public.audit_logs enable row level security;
drop policy if exists "audit_admin_read" on public.audit_logs;
create policy "audit_admin_read" on public.audit_logs for select to authenticated using (public.is_admin());

create table if not exists public.support_resources (
  id uuid primary key default gen_random_uuid(),
  organization text not null,
  service_name text not null,
  phone_number text, sms_number text, whatsapp_number text, website text, email text,
  location text, operating_hours text, emergency boolean not null default false,
  description text, status text not null default 'DRAFT', updated_at timestamptz not null default now()
);
create index if not exists idx_support_resources_status on public.support_resources(status);
alter table public.support_resources enable row level security;
drop policy if exists "support_public_read" on public.support_resources;
drop policy if exists "support_admin_write" on public.support_resources;
create policy "support_public_read" on public.support_resources for select to anon,authenticated using (status='PUBLISHED');
create policy "support_admin_write" on public.support_resources for all to authenticated using (public.has_admin_role(array['SUPER_ADMIN','ADMIN','SUPPORT_ADMIN'])) with check (public.has_admin_role(array['SUPER_ADMIN','ADMIN','SUPPORT_ADMIN']));
