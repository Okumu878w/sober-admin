# Implementation notes

This admin panel was added beside the existing Android app under `admin/` so the Android source remains intact.

## Existing Android compatibility observed
The supplied Android project already uses Supabase and reads:
- events through `v_events`
- resources through `resources` where `is_active = true`
- virtual groups through `v_virtual_groups` where `is_active = true`
- community reports through `content_reports`
- profiles through `profiles`

The Android DTOs use event fields including `event_date`, `event_type`, `rsvp_count`, `max_attendees`, `image_url`, `is_virtual`, and organizer information. Resources use `title`, `description`, `url`, `resource_type`, `thumbnail_url`, `author`, `duration_minutes`, `view_count`, and `is_active`. Virtual groups use `scheduled_time`, `recurrence`, `max_participants`, `member_count`, `meeting_link`, and host information.

The migrations therefore add administrative status/metadata columns rather than renaming the existing application-facing columns.

## Important production step
Because the supplied project does not contain the complete live Supabase SQL schema, migration `002_content_compatibility.sql` is intentionally additive and should be reviewed against the live database before execution. Do not blindly run destructive schema changes.

The browser app never contains a service-role key. RLS and Storage policies enforce authorization on the backend.

## Demo mode
Set `VITE_DEMO_MODE=true` only to demonstrate the UI without Supabase credentials. Demo data is isolated in `src/lib/demo.ts` and is explicitly labelled in the login screen.


## Supabase schema alignment completed
The supplied `supabase.zip` was reviewed against the admin implementation. The production alignment migration `006_admin_production_alignment.sql` now:
- removes legacy broad `is_staff()` policies from events, resources and groups so the new admin roles are actually enforced by RLS;
- adds moderation review metadata and the ESCALATED state;
- uses the existing `group_meeting_details` table for meeting credentials instead of writing non-existent columns into `virtual_support_groups`;
- rebuilds `v_virtual_groups` with the administrative fields while preserving the Android-facing fields;
- exposes the existing moderation queue through `v_open_reports`;
- grants the privileges required after the base schema's restrictive `REVOKE`;
- configures the dedicated `sober-resources` bucket as public only for intentionally published application resources, rather than opening unrelated storage buckets.

The admin API now uses `resolve_report()` for hide/dismiss moderation actions, validates resource file type/size, stores the actual Storage path, and safely removes an old file only after the database update succeeds.

The provided Supabase schema remains the source of truth. No Android table or existing application-facing column was renamed or removed.
