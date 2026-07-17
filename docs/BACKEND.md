# Atlas — Backend (Supabase)

**Status:** M5 complete — email/password auth, anonymous upgrade, and profile sign-in UI.  
**Next:** Post-MVP enhancements (Google/Apple OAuth, moderation tools) — awaiting approval.

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

## M5 deliverables (current)

### Auth layers

| Layer | Role |
|---|---|
| `domain/auth_repository.dart` | Abstract `ChangeNotifier` interface |
| `data/supabase_auth_repository.dart` | Sign-up, sign-in, sign-out, anonymous upgrade |
| `data/auth_credentials_validator.dart` | Email/password validation |
| `presentation/auth_scope.dart` | Inherited scope |
| `presentation/widgets/profile_account_section.dart` | Profile account card |
| `presentation/widgets/auth_form_sheet.dart` | Sign-in / sign-up bottom sheet |

### Bootstrap

`AppShell` instancie `SupabaseAuthRepository` et relance la synchronisation profil / favoris / signalements après chaque changement de session.

### Behaviour

1. **Offline-first preserved** — sans Supabase configuré, l'app reste 100 % locale.
2. **Sign-up** — si session anonyme active, `updateUser` conserve le même `user_id` (pas de perte de données synchronisées).
3. **Sign-in** — connexion à un compte existant ; les données locales restent et fusionnent en arrière-plan.
4. **Sign-out** — déconnexion puis nouvelle session anonyme ; SharedPreferences inchangé.
5. **UI** — section « Compte Atlas » sur l'écran Profil uniquement.

---

## M4 deliverables

### Database

| File | Role |
|---|---|
| `supabase/migrations/00005_content_reports.sql` | `content_reports` table + RLS (per-user rows) |

### Repository layers

| Layer | Role |
|---|---|
| `domain/content_reports_repository.dart` | Abstract `ChangeNotifier` interface |
| `data/local_content_reports_repository.dart` | SharedPreferences only (permanent fallback) |
| `data/supabase_content_reports_repository.dart` | Fetch + insert |
| `data/content_reports_sync_coordinator.dart` | Status merge rules |
| `data/syncing_content_reports_repository.dart` | Local-first + background sync |
| `data/content_reports_preferences_store.dart` | Reports JSON + `syncPending` |

### Bootstrap

`AppShell` instancie `SyncingContentReportsRepository` directement (cycle de vie par session).

### Sync behaviour

1. `load()` — local immediately, then background pull status / push pending inserts.
2. `submitReport()` — local immediately, then background insert.
3. Offline push failure → `content_reports_sync_pending = true`, silent retry on next `load()`.
4. Client inserts are immutable; moderation updates `status` via service role.
5. Conflict: newer `updated_at` wins for status; equal timestamps → remote status wins.

---

## M3 deliverables

### Database

| File | Role |
|---|---|
| `supabase/migrations/00004_favorites.sql` | `favorites` table + RLS (per-user rows) |

### Repository layers

| Layer | Role |
|---|---|
| `domain/favorites_repository.dart` | Abstract `ChangeNotifier` interface |
| `data/local_favorites_repository.dart` | SharedPreferences only (permanent fallback) |
| `data/supabase_favorites_repository.dart` | Fetch + upsert |
| `data/favorites_sync_coordinator.dart` | Per-item conflict merge rules |
| `data/syncing_favorites_repository.dart` | Local-first + background sync |
| `data/favorites_preferences_store.dart` | Favorites + `syncPending` |

### Bootstrap

`AppShell` instancie `SyncingFavoritesRepository` directement (cycle de vie par session).

### Sync behaviour

1. `load()` — local immediately, then background pull/merge/push.
2. `addFavorite()` / `removeFavorite()` — local immediately, mark `syncPending`, then upsert.
3. Offline / failed push → `favorites_sync_pending = true`, silent retry on next `load()`.
4. Conflict: per `(entity_type, entity_slug)`, newer `updated_at` wins; equal timestamps → local wins.
5. While `syncPending` is true, local wins over a newer remote tombstone (avoids wipe before push).
6. Tombstones (`is_active = false`) preserve removals for multi-device sync; local storage keeps active rows only after a successful push.

---

## M2 deliverables

### Database

| File | Role |
|---|---|
| `supabase/migrations/00003_profiles.sql` | `profiles` table + RLS (1:1 with `auth.users`) |

### Repository layers

| Layer | Role |
|---|---|
| `domain/profile_repository.dart` | Abstract `ChangeNotifier` interface + factory |
| `data/local_profile_repository.dart` | SharedPreferences only (permanent fallback) |
| `data/supabase_profile_repository.dart` | Fetch + upsert |
| `data/profile_sync_coordinator.dart` | Conflict merge rules |
| `data/syncing_profile_repository.dart` | Local-first + background sync |
| `data/profile_preferences_store.dart` | Profile + `localUpdatedAt` + `syncPending` |

### Bootstrap

`AppShell` instancie `SyncingProfileRepository` directement (cycle de vie par session).

### Sync behaviour

1. `load()` — local immediately, then background pull/merge/push.
2. `save()` — local immediately, then background upsert.
3. Offline push failure → `profile_sync_pending = true`, silent retry on next `load()`.
4. Conflict: newer `updated_at` wins; equal timestamps → local wins.
5. Remote applies only when `profile_local_updated_at` is absent (no local edits).

---

## M1 deliverables

### Database

| File | Role |
|---|---|
| `supabase/migrations/00002_editorial_tables.sql` | `procedures`, `places`, `prices` tables + RLS |
| `supabase/seed.sql` | SQL seed from static Dart catalogs |

Regenerate seed after catalog edits:

```bash
flutter test test/tool/generate_editorial_seed_test.dart
```

### Repository layers (per feature)

| Layer | Role |
|---|---|
| `domain/*_repository.dart` | Abstract interface + factory registration |
| `data/local_*_repository.dart` | Static catalog (permanent fallback) |
| `data/supabase_*_repository.dart` | Read-only Supabase fetch |
| `data/resilient_*_repository.dart` | Remote first, local on failure/empty |
| `data/*_record_mapper.dart` | Postgres row → domain model |

### Bootstrap

`EditorialRepositoryBootstrap.registerDefaults()` in `main.dart` wires resilient repos.  
`EditorialRepositoryBootstrap.warmUp()` preloads Supabase data when configured.

### Behaviour

1. Sync API unchanged — pages call `ProcedureRepository()` etc. as before.
2. First read uses local catalog; remote cache applied after `warmUp()`.
3. Supabase failure → silent fallback to static catalogs.
4. UI/widgets unchanged — only import paths and factory registration.

---

## M0 deliverables

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

Local `SharedPreferences` remains the immediate read/write path; Supabase is synchronized in the background.

### `prices`

Editorial price guides. Arrays: `price_factors`, `warning_signs`, `negotiation_tips`.  
`icon_key` stored as string; mapped to `IconData` in Dart.

### `procedures`

Admin step-by-step guides. Arrays: `documents`, `steps`.

### `places`

Curated places. `image_color` as `#RRGGBB` hex.

### `events`

Calendrier éditorial Maroc (`supabase/migrations/00007_events.sql`).

| Column | Type | Notes |
|---|---|---|
| `slug` | `text` UNIQUE | Dart `AtlasEvent.id` |
| `category` | `text` | `publicHoliday` \| `religious` \| `schoolHoliday` \| `nationalEvent` \| `culturalFestival` \| `sports` \| `travelPeak` |
| `start_at` / `end_at` | `date` | Civil dates |
| `city_name` | `text` nullable | `null` = national |
| `reliability` | `text` | `confirmed` \| `provisional` \| `estimated` |
| `source` / `source_url` | text | Attribution obligatoire |
| `last_verified_at` | `timestamptz` | |
| `audience_tags` | `text[]` | optional |
| `is_published` | `boolean` | RLS SELECT when true |

Local Flutter fallback (`EventCatalog`) contains **only** fixed civil public holidays. Festivals, sports, school holidays, travel peaks and religious dates are Supabase-only when an editor publishes them.

### `favorites`

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK | |
| `user_id` | `uuid` | FK → `auth.users` |
| `entity_type` | `text` | `price` \| `procedure` \| `place` |
| `entity_slug` | `text` | |
| `is_active` | `boolean` | `false` = tombstone de suppression |
| `created_at` / `updated_at` | `timestamptz` | auto + trigger |

Unique: `(user_id, entity_type, entity_slug)`.

### `content_reports`

| Column | Type | Notes |
|---|---|---|
| `id` | `uuid` PK | client-generated before insert |
| `user_id` | `uuid` | FK → `auth.users` |
| `entity_type` | `text` | `price` \| `procedure` \| `place` |
| `entity_slug` | `text` | |
| `report_type` | `text` | `outdated` \| `incorrect` \| `missing_info` \| `other` |
| `details` | `text` | 1–2000 chars |
| `status` | `text` | `pending` \| `reviewed` \| `dismissed` |
| `created_at` / `updated_at` | `timestamptz` | auto + trigger |

---

## Row Level Security (planned)

| Table | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| Editorial (`prices`, `procedures`, `places`, `events`) | published rows, all users | service role only | service role only | service role only |
| `profiles` | own row | own row | own row | deny |
| `favorites` | own rows | own rows | own rows | own rows |
| `content_reports` | own rows | own rows | service role | deny |
| `app_health` | all (M0) | service role | service role | service role |

---

## Authentication roadmap

| Phase | Auth | UI |
|---|---|---|
| **M0** ✓ | Anonymous session (silent) | None |
| **M2** ✓ | Profile sync (anonymous) | None |
| **M3** ✓ | Favorites (anonymous) | None |
| **M4** ✓ | Content reports (anonymous) | None |
| **M5** ✓ | Email/password + anonymous upgrade | Profile account section |
| Post-MVP | Google / Apple OAuth | Sign-in screens |

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
4. Favorites (M3) ✓
5. Content reports (M4) ✓
6. Account linking UI (M5) ✓

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

M0–M5 migration complete. OAuth providers remain post-MVP.
