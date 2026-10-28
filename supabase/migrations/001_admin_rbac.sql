-- Sober Connect Admin RBAC. Additive migration: does not delete existing application data.
create table if not exists public.admin_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  email text,
  role text not null default 'READ_ONLY' check (role in ('SUPER_ADMIN','ADMIN','EVENTS_ADMIN','CONTENT_ADMIN','MODERATOR','SUPPORT_ADMIN','READ_ONLY')),
  status text not null default 'ACTIVE' check (status in ('ACTIVE','DISABLED')),
  created_at timestamptz not null default now(),
  last_activity_at timestamptz
);

create index if not exists idx_admin_profiles_role on public.admin_profiles(role);
create index if not exists idx_admin_profiles_status on public.admin_profiles(status);

create or replace function public.has_admin_role(required_roles text[])
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.admin_profiles a
    where a.id = auth.uid() and a.status = 'ACTIVE' and a.role = any(required_roles)
  );
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select public.has_admin_role(array['SUPER_ADMIN','ADMIN','EVENTS_ADMIN','CONTENT_ADMIN','MODERATOR','SUPPORT_ADMIN','READ_ONLY']); $$;

grant execute on function public.has_admin_role(text[]) to authenticated;
grant execute on function public.is_admin() to authenticated;

alter table public.admin_profiles enable row level security;
drop policy if exists "admin_profiles_self_read" on public.admin_profiles;
drop policy if exists "admin_profiles_super_admin_manage" on public.admin_profiles;
create policy "admin_profiles_self_read" on public.admin_profiles for select to authenticated using (id = auth.uid() or public.has_admin_role(array['SUPER_ADMIN']));
create policy "admin_profiles_super_admin_manage" on public.admin_profiles for all to authenticated using (public.has_admin_role(array['SUPER_ADMIN'])) with check (public.has_admin_role(array['SUPER_ADMIN']));

-- First super admin procedure (run manually with a real auth.users UUID):
-- insert into public.admin_profiles (id,display_name,email,role) values ('AUTH-USER-UUID','Your Name','verified-email@example.org','SUPER_ADMIN');
