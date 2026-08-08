-- P0 stage 1: additive insert of missing Explorer places (stable slugs).
-- Safe for remote apply later: no TRUNCATE, no DELETE, no overwrite of existing rows.
-- place-majorelle is intentionally omitted so the live remote row is never replaced.
-- Each INSERT uses ON CONFLICT (slug) DO NOTHING (idempotent, no duplicates).
-- Ensures places.image exists for schema parity with 00013 (idempotent ADD COLUMN).

ALTER TABLE places
  ADD COLUMN IF NOT EXISTS image text;

INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours, image
) VALUES (
  'place-bahia',
  'Palais de la Bahia',
  'Marrakech',
  'monument',
  'Monument',
  'Médina',
  '€€',
  false,
  '#C4654A',
  'Palais du XIXe siècle aux décors somptueux — un des plus beaux exemples d''architecture andalouse à Marrakech.',
  ARRAY['Arrivez à l''ouverture pour profiter de la lumière dans les patios.', 'Prévoyez 1h à 1h30 pour la visite complète.', 'Les cours intérieures sont ombragées — idéal en été.'],
  'En matinée, hors week-end si possible',
  'https://maps.google.com/?q=Palais+de+la+Bahia+Marrakech',
  NULL,
  31.6214,
  -7.9836,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL,
  NULL
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours, image
) VALUES (
  'place-jemaa-el-fna',
  'Place Jemaa el-Fna',
  'Marrakech',
  'souk',
  'Souk',
  'Médina',
  '€',
  true,
  '#8B4513',
  'Cœur battant de la Médina — spectacles de rue, étals de nourriture et artisanat dès la tombée du jour.',
  ARRAY['Négociez les prix dans les souks — c''est la coutume.', 'Goûtez les jus d''orange frais des étals de la place.', 'Restez vigilant sur vos affaires dans la foule du soir.'],
  'Fin d''après-midi et soirée',
  'https://maps.google.com/?q=Jemaa+el-Fna+Marrakech',
  NULL,
  31.6258,
  -7.9891,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL,
  NULL
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours, image
) VALUES (
  'place-ysl-museum',
  'Musée Yves Saint Laurent',
  'Marrakech',
  'musee',
  'Musée',
  'Gueliz',
  '€€€',
  false,
  '#1A1A2E',
  'Musée dédié à Yves Saint Laurent, voisin du Jardin Majorelle — mode, design et héritage culturel.',
  ARRAY['Le billet combiné Jardin Majorelle + musée est souvent avantageux.', 'La photographie est interdite dans certaines salles.', 'Comptez 1h pour la visite du musée seul.'],
  'En semaine, milieu de matinée',
  'https://maps.google.com/?q=Musée+Yves+Saint+Laurent+Marrakech',
  NULL,
  31.6417,
  -8.0025,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL,
  NULL
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours, image
) VALUES (
  'place-hammam-marrakech',
  'Hammam traditionnel',
  'Marrakech',
  'hammam',
  'Hammam',
  'Médina',
  '€€',
  false,
  '#5C7A8A',
  'Expérience authentique de bain maure — gommage, vapeur et détente après une journée dans la Médina.',
  ARRAY['Apportez votre propre savon noir et gant de kessa si possible.', 'Les hammams locaux sont mixtes par créneaux horaires — renseignez-vous.', 'Prévoyez 1h30 à 2h pour l''expérience complète.'],
  'Fin d''après-midi',
  'https://maps.google.com/?q=Hammam+Médina+Marrakech',
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL,
  NULL
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours, image
) VALUES (
  'place-hassan-ii',
  'Mosquée Hassan II',
  'Casablanca',
  'monument',
  'Monument',
  'Corniche',
  '€€',
  true,
  '#1B4965',
  'Deuxième plus grande mosquée au monde — architecture spectaculaire dominant l''Atlantique.',
  ARRAY['Les visites guidées sont obligatoires pour les non-musulmans.', 'Retirez vos chaussures et habillez-vous modestement.', 'La visite dure environ 1h — réservez à l''avance en haute saison.'],
  'Visite guidée le matin',
  'https://maps.google.com/?q=Mosquée+Hassan+II+Casablanca',
  NULL,
  33.6085,
  -7.6326,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL,
  NULL
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours, image
) VALUES (
  'place-corniche',
  'Corniche Ain Diab',
  'Casablanca',
  'plage',
  'Plage',
  'Ain Diab',
  '€€',
  false,
  '#48CAE4',
  'Promenade en bord de mer avec plages, cafés et restaurants — incontournable de Casablanca.',
  ARRAY['Le stationnement est difficile le week-end — privilégiez un taxi.', 'Les plages publiques sont gratuites, les clubs de plage sont payants.', 'Idéal pour un coucher de soleil suivi d''un dîner en bord de mer.'],
  'Fin d''après-midi en semaine',
  'https://maps.google.com/?q=Corniche+Ain+Diab+Casablanca',
  NULL,
  33.595,
  -7.677,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL,
  NULL
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours, image
) VALUES (
  'place-marche-central',
  'Marché Central',
  'Casablanca',
  'restaurant',
  'Restaurant',
  'Centre-ville',
  '€',
  true,
  '#E07A5F',
  'Marché couvert historique transformé en food court — fruits de mer, cuisine marocaine et ambiance locale.',
  ARRAY['Les étals de poisson grillé sont les plus populaires.', 'Arrivez tôt pour avoir une table aux heures de pointe.', 'Les prix sont affichés — peu de négociation ici.'],
  'Déjeuner entre 12h et 14h',
  'https://maps.google.com/?q=Marché+Central+Casablanca',
  NULL,
  33.594,
  -7.618,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL,
  NULL
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours, image
) VALUES (
  'place-musee-judaisme',
  'Musée du Judaïsme Marocain',
  'Casablanca',
  'musee',
  'Musée',
  'Centre-ville',
  '€€',
  false,
  '#6B4226',
  'Musée unique retraçant l''histoire millénaire du judaïsme marocain dans un ancien temple.',
  ARRAY['Fermé le samedi — vérifiez les horaires avant de vous déplacer.', 'La visite guidée enrichit beaucoup l''expérience.', 'Comptez 1h pour une visite complète.'],
  'Matinée en semaine',
  'https://maps.google.com/?q=Musée+du+Judaïsme+Casablanca',
  NULL,
  33.601,
  -7.631,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL,
  NULL
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours, image
) VALUES (
  'place-habous',
  'Quartier Habous',
  'Casablanca',
  'souk',
  'Souk',
  'Habous',
  '€',
  false,
  '#D4A373',
  'Quartier néo-traditionnel avec souks, pâtisseries et artisanat — alternative plus calme à la Médina de Marrakech.',
  ARRAY['Les pâtisseries orientales du quartier sont réputées.', 'Moins touristique que la Médina — les prix sont plus doux.', 'Idéal pour acheter des souvenirs artisanaux.'],
  'Matinée',
  'https://maps.google.com/?q=Quartier+Habous+Casablanca',
  NULL,
  33.5735,
  -7.606,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL,
  NULL
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours, image
) VALUES (
  'place-tour-hassan',
  'Tour Hassan',
  'Rabat',
  'monument',
  'Monument',
  'Centre-ville',
  '€',
  true,
  '#B5835A',
  'Minaret inachevé du XIIe siècle et esplanade monumentale — symbole emblématique de Rabat.',
  ARRAY['L''esplanade est gratuite et ouverte en continu.', 'Combinez avec la visite du Mausolée Mohammed V juste en face.', 'Très photogénique au coucher du soleil.'],
  'Fin d''après-midi pour la lumière',
  'https://maps.google.com/?q=Tour+Hassan+Rabat',
  NULL,
  34.0242,
  -6.8227,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL,
  NULL
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours, image
) VALUES (
  'place-oudayas',
  'Kasbah des Oudayas',
  'Rabat',
  'monument',
  'Monument',
  'Oudayas',
  '€',
  true,
  '#3D5A80',
  'Citadelle aux ruelles bleues et blanches surplombant l''embouchure du Bouregreg — le quartier le plus pittoresque de Rabat.',
  ARRAY['Les ruelles sont étroites — chaussures confortables recommandées.', 'Le café Maure offre une vue magnifique sur le fleuve.', 'Moins de monde tôt le matin.'],
  'Matinée en semaine',
  'https://maps.google.com/?q=Kasbah+des+Oudayas+Rabat',
  NULL,
  34.0319,
  -6.8369,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL,
  NULL
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours, image
) VALUES (
  'place-chellah',
  'Chellah',
  'Rabat',
  'monument',
  'Monument',
  'Chellah',
  '€€',
  false,
  '#588157',
  'Site archéologique romain et médiéval aux jardins luxuriants — havre de paix en ville.',
  ARRAY['Les nids de storks sur les ruines sont spectaculaires au printemps.', 'Prévoyez 1h30 pour explorer le site en entier.', 'Ombragé et frais — idéal par temps chaud.'],
  'Matinée, surtout au printemps',
  'https://maps.google.com/?q=Chellah+Rabat',
  NULL,
  34.0065,
  -6.8206,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL,
  NULL
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours, image
) VALUES (
  'place-musee-rabat',
  'Musée Mohammed VI',
  'Rabat',
  'musee',
  'Musée',
  'Centre-ville',
  '€€',
  false,
  '#7B2D26',
  'Musée d''art moderne et contemporain africain — collection remarquable dans une architecture épurée.',
  ARRAY['Fermé le mardi — vérifiez les horaires.', 'La collection permanente est accessible avec un seul billet.', 'Comptez 1h30 pour une visite confortable.'],
  'Après-midi en semaine',
  'https://maps.google.com/?q=Musée+Mohammed+VI+Rabat',
  NULL,
  34.0125,
  -6.844,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL,
  NULL
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours, image
) VALUES (
  'place-plage-rabat',
  'Plage de Rabat',
  'Rabat',
  'plage',
  'Plage',
  'Plage des Oudayas',
  '€',
  false,
  '#90E0EF',
  'Plage urbaine accessible depuis la Kasbah — idéale pour une pause fraîcheur en été.',
  ARRAY['La plage est surveillée en été.', 'Accessible à pied depuis la Kasbah des Oudayas.', 'Évitez les week-ends d''été si vous cherchez le calme.'],
  'Fin d''après-midi',
  'https://maps.google.com/?q=Plage+Rabat',
  NULL,
  34.028,
  -6.845,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL,
  NULL
) ON CONFLICT (slug) DO NOTHING;
