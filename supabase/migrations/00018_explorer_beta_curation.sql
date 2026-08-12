-- Explorer Marrakech beta curation.
-- Editorial Sélection Atlas only — not popularity / ratings / trending.
-- Does not delete place rows; retires obsolete hammam from published feed.

-- Prevent retired generic hammam from resurfacing via resilient merge.
UPDATE places
SET is_published = false,
    updated_at = now()
WHERE slug = 'place-hammam-marrakech';

-- Clear Marrakech editors picks only, then apply beta core (~18).
UPDATE places
SET is_editors_pick = false,
    updated_at = now()
WHERE city_name = 'Marrakech'
  AND is_editors_pick = true;

UPDATE places
SET is_editors_pick = true,
    updated_at = now()
WHERE slug = ANY (
  ARRAY[
    'place-jemaa-el-fna',
    'place-majorelle',
    'place-bahia',
    'place-koutoubia',
    'place-medersa-ben-youssef',
    'place-el-badi',
    'place-tombeaux-saadiens',
    'place-ysl-museum',
    'place-musee-dar-el-bacha',
    'place-maison-de-la-photographie',
    'place-les-bains-marrakech',
    'place-al-fassia-gueliz',
    'place-amal-gueliz',
    'place-nomad',
    'place-bacha-coffee',
    'place-cafe-des-epices',
    'place-cafe-clock',
    'place-macaal'
  ]::text[]
);

-- Neighborhood spelling consistency (Majorelle).
UPDATE places
SET neighborhood = 'Guéliz',
    updated_at = now()
WHERE slug = 'place-majorelle'
  AND neighborhood = 'Gueliz';
