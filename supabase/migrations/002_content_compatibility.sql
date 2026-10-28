-- Compatibility additions for the existing Sober Connect tables.
-- Review the live schema before production deployment. Existing columns are preserved.

alter table if exists public.events add column if not exists status text not null default 'DRAFT';
alter table if exists public.events add column if not exists start_time time;
alter table if exists public.events add column if not exists end_time time;
alter table if exists public.events add column if not exists timezone text not null default 'Africa/Nairobi';
alter table if exists public.events add column if not exists address text;
alter table if exists public.events add column if not exists city text;
alter table if exists public.events add column if not exists country text default 'Kenya';
alter table if exists public.events add column if not exists meeting_instructions text;
alter table if exists public.events add column if not exists contact_name text;
alter table if exists public.events add column if not exists contact_email text;
alter table if exists public.events add column if not exists contact_phone text;
alter table if exists public.events add column if not exists published_at timestamptz;
alter table if exists public.events add column if not exists cancellation_reason text;
alter table if exists public.events add column if not exists allow_waitlist boolean not null default true;
alter table if exists public.events add column if not exists created_by uuid;
create index if not exists idx_events_status_date on public.events(status,event_date);

alter table if exists public.resources add column if not exists status text not null default 'DRAFT';
alter table if exists public.resources add column if not exists provider text;
alter table if exists public.resources add column if not exists language text;
alter table if exists public.resources add column if not exists region text;
alter table if exists public.resources add column if not exists tags text[] not null default '{}';
alter table if exists public.resources add column if not exists file_path text;
alter table if exists public.resources add column if not exists created_by uuid;
alter table if exists public.resources add column if not exists published_at timestamptz;
create index if not exists idx_resources_status_type on public.resources(status,resource_type);

alter table if exists public.virtual_support_groups add column if not exists status text not null default 'DRAFT';
alter table if exists public.virtual_support_groups add column if not exists meeting_instructions text;
create index if not exists idx_groups_status_schedule on public.virtual_support_groups(status,scheduled_time);
