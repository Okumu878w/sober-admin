create or replace function public.audit_admin_change()
returns trigger language plpgsql security definer set search_path=public
as $$
declare
  action_name text;
  entity_id_value text;
begin
  if auth.uid() is null or not public.is_admin() then return coalesce(NEW,OLD); end if;
  action_name := tg_op || '_' || upper(tg_table_name);
  entity_id_value := coalesce((to_jsonb(NEW)->>'id'),(to_jsonb(OLD)->>'id'));
  insert into public.audit_logs(admin_user,action,entity_type,entity_id,metadata)
  values(auth.uid(),action_name, tg_table_name, entity_id_value, jsonb_build_object('source','admin_panel'));
  return coalesce(NEW,OLD);
end;
$$;

drop trigger if exists audit_events on public.events;
create trigger audit_events after insert or update or delete on public.events for each row execute function public.audit_admin_change();
drop trigger if exists audit_resources on public.resources;
create trigger audit_resources after insert or update or delete on public.resources for each row execute function public.audit_admin_change();
drop trigger if exists audit_groups on public.virtual_support_groups;
create trigger audit_groups after insert or update or delete on public.virtual_support_groups for each row execute function public.audit_admin_change();
