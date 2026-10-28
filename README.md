# Sober Connect Admin

Production-oriented React + TypeScript admin panel for the existing Sober Connect Android/Supabase application.

## Stack
- React + TypeScript + Vite
- Supabase Auth/Postgres/Storage
- Native CSS with accessible responsive components
- Vitest for core permission tests

## Run
1. Copy `.env.example` to `.env`.
2. Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
3. Run `npm install`.
4. Run `npm run dev`.
5. For production, run `npm run build` and deploy `dist/` to a static host.

If credentials are not available, set `VITE_DEMO_MODE=true`. Demo data is explicitly labelled and is never presented as production data.

## Supabase
Run migrations in `supabase/migrations` in order. They are additive and designed to preserve existing Sober Connect tables. Review the compatibility notes in each migration against the live schema before applying to production.

The browser must only receive the Supabase URL and anon/public key. Never place a `service_role` key in this project.

## First super admin
Create the staff user through Supabase Auth, then run the documented SQL insert in the RBAC migration using that authenticated user's UUID. There is no hard-coded credential.

## Android integration
The existing Android code reads events through `v_events`, resources from `resources`, and virtual groups through `v_virtual_groups`. The admin panel writes to the shared backend and publishes through status/active fields, so content changes do not require an APK update. The existing Android schema/DTOs should be treated as compatibility constraints.
