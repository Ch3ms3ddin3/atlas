# Atlas — Backend (Supabase)

**Status:** M0 complete — configuration, health check, anonymous session bootstrap.  
**Next:** M1 (read-only editorial sync) — awaiting approval.

---

## Goals

Replace Atlas’s static MVP data progressively with a secure Supabase backend while:

- keeping the app fully usable during migration,
- preserving static/local fallbacks permanently,
- ensuring the UI never depends directly on Supabase (repository interfaces only).

---

## Architecture principles

| Principle | Implementation |
|---|---|
| Repository interfaces | UI and features depend on abstract contracts; Supabase is one implementation |
| Offline-first reads | Static Dart catalogs remain the guaranteed fallback |
| Non-fatal backend | Bootstrap and health-check failures never block `runApp` |
| UUID + slug | Postgres PKs are `uuid`; stable string `slug` fields match existing Dart ids |
| Anonymous first | Silent `signInAnonymously()` when configured; email/Google/Apple later |
| SQL seeds | Editorial content seeded via `supabase/seed.sql` (M1+) |
| No service-role in app | Only `SUPABASE_URL` + `SUPABASE_ANON_KEY` in the client |

---

## Environments

Three compile-time environments via `ATLAS_ENV`:

| Value | Use |
|---|---|
| `development` | Local dev, Supabase dev project |
| `staging` | Pre-release QA |
| `production` | Store builds |

### Local run

```bash
cp .env.development.example .env.development
# Edit SUPABASE_URL and SUPABASE_ANON_KEY

flutter run --dart-define-from-file=.env.development
```

### CI / release

Inject secrets as ephemeral env files or `--dart-define` pairs. Never commit real `.env.*` files.

---

## M0 deliverables (current)

### Flutter

| File | Role |
|---|---|
| `lib/core/config/atlas_env.dart` | Reads `ATLAS_ENV`, `SUPABASE_URL`, `SUPABASE_ANON_KEY` |
| `lib/core/backend/backend_health_repository.dart` | Abstract health-check contract |
| `lib/core/backend/backend_health_status.dart` | Health result model |
| `lib/core/supabase/supabase_bootstrap.dart` | Init Supabase + silent anonymous session |
| `lib/core/supabase/supabase_health_repository.dart` | Supabase health implementation |

### Supabase

| File | Role |
|---|---|
| `supabase/config.toml` | CLI config; anonymous sign-ins enabled |
| `supabase/migrations/00001_app_health.sql` | Health ping table + RLS read policy |

### Behaviour

1. If env vars are missing → Supabase skipped; app runs on static/local data only.
2. If env vars present → `Supabase.initialize`, then anonymous session if none exists.
3. On failure → debug log only; app continues with local/static fallback.
4. Debug builds log health-check result after bootstrap (no UI change).

---

## Secrets policy

### Safe in the Flutter app

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` (public, RLS-protected)

### Never in the repo or client

- `SUPABASE_SERVICE_ROLE_KEY`
- Database passwords
- JWT signing secrets

`.gitignore` excludes `.env` and `.env.*` except `*.example` templates.

---

## Planned schema (M1+)

All editorial tables use **`id uuid PRIMARY KEY`** and a separate **`slug text UNIQUE NOT NULL`** matching current Dart ids (e.g. `price-taxi-marrakech`).

### `profiles`

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK | FK → `auth.users(id)` |
| `first_name` | `text` | required |
| `preferred_city` | `text` | required |
| `language` | `text` | `french` \| `english` \| `arabic` |
| `user_type` | `text` | `resident` \| `mre` \| `visitor` |
| `created_at` / `updated_at` | `timestamptz` | auto + trigger |

Local `SharedPreferences` profile remains source of truth until explicit sign-in (M5).

### `prices`

Editorial price guides. Arrays: `price_factors`, `warning_signs`, `negotiation_tips`.  
`icon_key` stored as string; mapped to `IconData` in Dart.

### `procedures`

Admin step-by-step guides. Arrays: `documents`, `steps`.

### `places`

Curated places. `image_color` as `#RRGGBB` hex.

### `favorites`

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK | |
| `user_id` | `uuid` | FK → `auth.users` |
| `entity_type` | `text` | `price` \| `procedure` \| `place` |
| `entity_slug` | `text` | |
| `created_at` | `timestamptz` | |

Unique: `(user_id, entity_type, entity_slug)`.

### `content_reports`

User corrections. Status: `pending` \| `reviewed` \| `dismissed`.

---

## Row Level Security (planned)

| Table | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| Editorial (`prices`, `procedures`, `places`) | published rows, all users | service role only | service role only | service role only |
| `profiles` | own row | own row | own row | deny |
| `favorites` | own rows | own rows | deny | own rows |
| `content_reports` | own rows | own rows | service role | deny |
| `app_health` | all (M0) | service role | service role | service role |

---

## Authentication roadmap

| Phase | Auth | UI |
|---|---|---|
| **M0** ✓ | Anonymous session (silent) | None |
| M3 | Anonymous (favorites) | None |
| M5 | Email, Google, Apple + account linking | Sign-in screens |

Anonymous sessions are created in `SupabaseBootstrap` when Supabase is configured and auth is enabled on the project.

---

## Repository migration pattern (M1+)

Each feature gets an abstract repository in `domain/` or `data/`:

```
abstract class PriceRepository { ... }

LocalPriceRepository      → static PriceCatalog (permanent fallback)
SupabasePriceRepository   → Postgres reads
ResilientPriceRepository  → remote first, catalog on failure/empty
```

UI pages receive `PriceRepository` via constructor or scope — never `SupabaseClient`.

### Migration order (after M0 approval)

1. Procedures (smallest catalog)
2. Places
3. Prices
4. Favorites (needs anonymous auth)
5. Content reports
6. Profile sync (needs sign-in UI)

---

## Supabase project setup

1. Create a Supabase project per environment (dev / staging / prod).
2. Enable **Anonymous sign-ins** in Authentication → Providers.
3. Apply migrations:

   ```bash
   supabase link --project-ref YOUR_PROJECT_REF
   supabase db push
   ```

4. Copy Project URL and anon key into the matching `.env.*` file.

---

## Testing

```bash
flutter analyze
flutter test
```

M0 tests cover env parsing, health repository (mocked probe), and app launch without Supabase configuration.

---

## What M0 does not do

- No feature reads from Supabase
- No auth screens
- No removal of static catalogs
- No UI or navigation changes

Wait for explicit approval before starting **M1**.
