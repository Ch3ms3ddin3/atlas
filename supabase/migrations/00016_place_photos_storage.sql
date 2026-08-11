-- Place photos Storage foundation.
-- Public bucket for curated cover / gallery WebPs referenced by places.image
-- and places.image_urls. No objects are uploaded by this migration.
--
-- Path convention (see docs/PLACE_PHOTOS.md):
--   place-photos/{slug}/cover.webp
--   place-photos/{slug}/gallery-01.webp (optional, future)
--
-- Writes: service role only (no INSERT/UPDATE/DELETE policies for anon/authenticated).
-- Reads: public (Explorer / Map / detail can load without auth).

INSERT INTO storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
VALUES (
  'place-photos',
  'place-photos',
  true,
  524288, -- 512 KiB hard cap; production covers target ≤ 300 KiB
  ARRAY['image/webp', 'image/jpeg', 'image/png']::text[]
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "place_photos_public_read" ON storage.objects;
CREATE POLICY "place_photos_public_read"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'place-photos');
