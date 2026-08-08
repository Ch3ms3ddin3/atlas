-- Primary cover image URL for Explorer cards / detail hero.
-- Gallery remains in image_urls (text[]); index 0 of the mapped list is
-- COALESCE(image, image_urls[1]) on the client.
ALTER TABLE places
  ADD COLUMN IF NOT EXISTS image text;
