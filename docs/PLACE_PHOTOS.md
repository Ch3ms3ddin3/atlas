# Atlas — Place photos

Production photo architecture for Explorer cards, place detail heroes, map
previews, and (later) galleries / Favorites covers.

**System of record:** Supabase Storage bucket `place-photos` + columns on
`places`. Do **not** hardcode new covers into Flutter assets for scale.

Related schema: `supabase/migrations/00013_place_primary_image.sql`,
`00006_place_detail_fields.sql`, `00016_place_photos_storage.sql`.  
Client mapping: `PlaceRecordMapper` (`image` then `image_urls`).  
UI: `PlaceCoverImage` (bundled → remote URL → color/icon fallback).

---

## Data model rules

| Column | Role |
|---|---|
| `places.image` | **Primary / cover** public URL (cards, hero, map preview). |
| `places.image_urls` | **Optional gallery** only (extra shots). Do not rely on this alone for the cover when `image` is set. |
| `places.image_color` | Editorial `#RRGGBB` tint for the honest placeholder when no photo loads. |

**Client behavior (unchanged):**

1. Build URL list as `[image?, ...image_urls]` with dedupe.
2. Cover widget priority today: verified **bundled** asset (legacy) → remote
   primary URL → `PlaceImageFallback` (color + category icon).
3. Missing or failed images **must** keep showing the graceful placeholder —
   never a broken-image glyph on Explorer cards.
4. Existing places without `image` / empty `image_urls` keep working.

**Do not** store Flutter asset paths (`assets/...`) in Supabase columns.

---

## Storage bucket

| Key | Value |
|---|---|
| Bucket id | `place-photos` |
| Public | yes (read) |
| Write | service role / admin only (no anon write policy) |
| Hard size limit | 512 KiB per object |
| Allowed MIME | `image/webp`, `image/jpeg`, `image/png` |

Migration: `supabase/migrations/00016_place_photos_storage.sql`.

Public object URL shape:

```text
https://<PROJECT_REF>.supabase.co/storage/v1/object/public/place-photos/<slug>/cover.webp
```

Set `places.image` to that URL after upload.

---

## Path & naming convention

```text
place-photos/
  {slug}/
    cover.webp           # required for a place that has a photo
    cover-thumb.webp     # optional later (list cards)
    gallery-01.webp      # optional future gallery
    gallery-02.webp
    …
```

- `{slug}` = stable place id (`PlaceGuide.id` / `places.slug`), e.g. `place-macaal`.
- Prefer **WebP** for production.
- Lowercase ASCII filenames; no spaces; use hyphens.
- One folder per place; replace `cover.webp` in place to update the cover
  without renaming (same URL + cache-bust via Storage upsert / cache headers
  when needed).

---

## Cover convention

- One **cover** per place: `{slug}/cover.webp`.
- Aspect: **3:2** landscape (e.g. **1800×1200** or **1600×1067**).
- **Target file size ≤ 300 KB** (hard Storage cap is 512 KiB — stay under 300 KB).
- Subject must match the place (no unrelated stock).
- License must be reusable for Atlas (document attribution before upload).

`places.image` = public URL of `cover.webp`.

---

## Future gallery convention

- Extra images: `{slug}/gallery-01.webp`, `gallery-02.webp`, …
- Same WebP / size discipline as covers (or slightly larger if needed, still ≤ 512 KiB).
- Store gallery public URLs in `places.image_urls` **without** duplicating the
  cover URL when `image` is already set.
- Detail UI already treats primary as hero and additional URLs as gallery.

---

## Preferred format & dimensions

| | Recommendation |
|---|---|
| Format | **WebP** (JPEG/PNG only as intermediate sources) |
| Cover dimensions | 1600×1067 or 1800×1200 (3:2) |
| Cover weight | **≤ 300 KB** |
| Thumb (later) | ~800×533, ≤ 100 KB |

---

## Replacement / update strategy

1. Prepare a new WebP locally (crop, compress, verify license).
2. Upload/overwrite `place-photos/{slug}/cover.webp` (service role).
3. Ensure `places.image` points at the public URL (unchanged path preferred).
4. If CDNs/clients cache aggressively, bump a query param only if required
   (`?v=2`) and update `places.image` accordingly — prefer long cache with
   overwrite + reasonable `Cache-Control` on the object.
5. **No app store release** required for photo updates.
6. Do **not** add new entries to `PlaceCoverAssets` / `pubspec.yaml` for new
   places — that path is legacy for the existing 13 bundled covers only.

---

## Fallback behavior

| Situation | UI |
|---|---|
| No `image`, empty `image_urls`, no bundled cover | Color + category icon placeholder |
| Remote URL missing / 404 / decode error | Same placeholder (`PlaceCoverImage` error widget) |
| Loading remote | Placeholder until fade-in |
| Bundled asset missing at runtime | Placeholder via `errorBuilder` |

Broken-image icons must not appear on Explorer / map cover surfaces.

---

## Caching (client)

- Remote covers load through `AtlasNetworkImage` → `cached_network_image`.
- Cover widgets pass `memCacheHeight` based on display height × device pixel ratio.
- Offline / poor network: last successful disk cache may show; otherwise placeholder.

---

## Marrakech missing-cover backlog (28)

Places with **no** remote `image` / `image_urls` in catalog/seed **and** no
entry in `PlaceCoverAssets`. Checklist for future sourcing/upload — **do not
fill with random web URLs**.

### Café (5)

- [ ] `place-bacha-coffee` — Bacha Coffee
- [ ] `place-simple-specialty-coffee` — Simple Specialty Coffee
- [ ] `place-cafe-des-epices` — Café des Épices
- [ ] `place-kartell-kollektiv` — Kartell Kollektiv
- [ ] `place-cafe-clock` — Café Clock

### Restaurant (11)

- [ ] `place-al-fassia-gueliz` — Al Fassia Guéliz
- [ ] `place-amal-gueliz` — Restaurant Amal Guéliz
- [ ] `place-nomad` — Nomad
- [ ] `place-plus61` — Plus61
- [ ] `place-le-jardin` — Le Jardin
- [ ] `place-sahbi-sahbi` — Sahbi Sahbi
- [ ] `place-grand-cafe-de-la-poste` — Le Grand Café de la Poste
- [ ] `place-catanzaro` — Catanzaro
- [ ] `place-naranj` — Naranj
- [ ] `place-la-trattoria` — La Trattoria
- [ ] `place-dar-moha` — Dar Moha

### Monument (4)

- [ ] `place-koutoubia` — Mosquée de la Koutoubia
- [ ] `place-medersa-ben-youssef` — Médersa Ben Youssef
- [ ] `place-tombeaux-saadiens` — Tombeaux Saadiens
- [ ] `place-el-badi` — Palais El Badi

*(Bahia already has a bundled cover.)*

### Musée (3)

- [ ] `place-musee-dar-el-bacha` — Musée des Confluences Dar El Bacha
- [ ] `place-maison-de-la-photographie` — Maison de la Photographie
- [ ] `place-macaal` — MACAAL

*(YSL already has a bundled cover.)*

### Jardin (1)

- [ ] `place-majorelle` — Jardin Majorelle

### Hammam (4)

- [ ] `place-les-bains-marrakech` — Les Bains de Marrakech
- [ ] `place-hammam-de-la-rose` — Hammam de la Rose
- [ ] `place-heritage-spa` — Heritage Spa
- [ ] `place-hammam-place-des-epices` — Hammam Place des Épices

### Souk

*(Jemaa el-Fna already has a bundled cover — no backlog item.)*

---

## Recommended first pilot

**Musée (3 missing)** — small, high visual impact, already validated category on
device. Upload `cover.webp` + set `places.image` for Dar El Bacha, Maison de la
Photographie, and MACAAL before larger Café/Restaurant batches.

---

## Out of scope for foundation

- Uploading or downloading photos
- Hotlinking Google Images / unverified URLs
- Changing Explorer / Map / Favorites UI
- Removing legacy `PlaceCoverAssets` (keep until Storage backfill is complete)
