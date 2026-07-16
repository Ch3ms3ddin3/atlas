-- Généré par test/tool/generate_editorial_seed_test.dart
BEGIN;

TRUNCATE TABLE procedures RESTART IDENTITY CASCADE;
TRUNCATE TABLE places RESTART IDENTITY CASCADE;
TRUNCATE TABLE prices RESTART IDENTITY CASCADE;
INSERT INTO procedures (
  slug, title, summary, category, category_label, estimated_duration,
  documents, steps, icon_key, official_url
) VALUES (
  'cin-renewal',
  'Renouveler la CIN',
  'Renouvellement de la Carte Nationale d''Identité pour les Marocains résidant au Maroc ou à l''étranger.',
  'identite',
  'Identité',
  '2 à 4 semaines',
  ARRAY['Ancienne CIN ou récépissé de déclaration de perte', 'Justificatif de domicile récent', 'Photos d''identité conformes', 'Formulaire de demande rempli'],
  ARRAY['Prendre rendez-vous en ligne ou se présenter à la commune de résidence.', 'Déposer le dossier complet au guichet dédié.', 'Payer les frais administratifs et conserver le récépissé.', 'Retirer la nouvelle CIN à la date indiquée sur le récépissé.'],
  'badge_outlined',
  'https://www.cnie.ma/'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO procedures (
  slug, title, summary, category, category_label, estimated_duration,
  documents, steps, icon_key, official_url
) VALUES (
  'residence-card',
  'Carte de séjour',
  'Demande ou renouvellement de la carte de séjour pour les étrangers résidant au Maroc.',
  'sejour',
  'Séjour',
  '1 à 3 mois',
  ARRAY['Passeport en cours de validité', 'Visa ou titre de séjour précédent', 'Justificatif de domicile au Maroc', 'Contrat de travail ou preuve de ressources', 'Photos d''identité'],
  ARRAY['Vérifier l''éligibilité selon votre motif de séjour.', 'Constituer le dossier et prendre rendez-vous à la préfecture.', 'Déposer la demande et payer les droits de timbre.', 'Suivre l''instruction du dossier et retirer la carte de séjour.'],
  'card_membership_outlined',
  'https://www.service-public.ma/'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO procedures (
  slug, title, summary, category, category_label, estimated_duration,
  documents, steps, icon_key, official_url
) VALUES (
  'driving-license',
  'Permis de conduire',
  'Échange ou obtention du permis de conduire marocain pour les résidents et MRE.',
  'transport',
  'Transport',
  '2 à 6 semaines',
  ARRAY['CIN ou carte de séjour en cours de validité', 'Permis étranger original (si échange)', 'Certificat médical d''aptitude', 'Photos d''identité', 'Justificatif de domicile'],
  ARRAY['Vérifier si votre pays a une convention d''échange avec le Maroc.', 'Passer le certificat médical dans un centre agréé.', 'Déposer le dossier à la NARSA ou en préfecture.', 'Retirer le permis marocain après validation du dossier.'],
  'directions_car_outlined',
  'https://www.service-public.ma/'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO procedures (
  slug, title, summary, category, category_label, estimated_duration,
  documents, steps, icon_key, official_url
) VALUES (
  'visa-extension',
  'Prolongation de visa',
  'Demande de prolongation d''un visa de court séjour depuis le Maroc.',
  'sejour',
  'Séjour',
  '1 à 3 semaines',
  ARRAY['Passeport et visa en cours de validité', 'Motif détaillé de la prolongation', 'Justificatif de moyens de subsistance', 'Réservation de retour ou poursuite de voyage'],
  ARRAY['Déposer la demande avant l''expiration du visa en cours.', 'Se présenter à la Direction Générale de la Sûreté Nationale (DGSN).', 'Fournir les justificatifs selon le motif (tourisme, affaires, etc.).', 'Retirer le récépissé ou le visa prolongé.'],
  'flight_land_outlined',
  'https://www.service-public.ma/'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO procedures (
  slug, title, summary, category, category_label, estimated_duration,
  documents, steps, icon_key, official_url
) VALUES (
  'admission-temporaire',
  'Admission temporaire véhicule',
  'Importation temporaire d''un véhicule étranger pour les MRE et touristes — validité limitée à 90 jours renouvelable.',
  'vehicule',
  'Véhicule',
  '1 à 2 jours',
  ARRAY['Passeport ou CIN', 'Carte grise du véhicule', 'Attestation d''assurance internationale', 'Permis de conduire valide'],
  ARRAY['Se présenter à la douane à l''entrée du territoire ou en bureau local.', 'Déclarer le véhicule et remplir le formulaire d''admission temporaire.', 'Payer la caution douanière si demandée.', 'Conserver le document dans le véhicule — surveiller la date d''expiration.'],
  'local_shipping_outlined',
  'https://www.douane.gov.ma/'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO procedures (
  slug, title, summary, category, category_label, estimated_duration,
  documents, steps, icon_key, official_url
) VALUES (
  'birth-certificate',
  'Extrait d''acte de naissance',
  'Demande d''extrait d''acte de naissance auprès de l''officier d''état civil de la commune de naissance.',
  'identite',
  'Identité',
  'Quelques jours',
  ARRAY['CIN du demandeur', 'Informations sur la personne concernée (nom, date, lieu de naissance)', 'Justificatif de lien de parenté si demande pour un tiers'],
  ARRAY['Identifier la commune d''enregistrement de la naissance.', 'Déposer la demande au bureau d''état civil ou en ligne si disponible.', 'Payer les frais de légalisation si nécessaire.', 'Retirer l''extrait ou le recevoir par voie postale.'],
  'description_outlined',
  'https://www.service-public.ma/'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO procedures (
  slug, title, summary, category, category_label, estimated_duration,
  documents, steps, icon_key, official_url
) VALUES (
  'tax-id',
  'Identifiant fiscal (IF)',
  'Obtention de l''identifiant fiscal pour les résidents devant ouvrir un compte, acheter un bien ou exercer une activité.',
  'identite',
  'Identité',
  '1 à 2 semaines',
  ARRAY['CIN ou carte de séjour', 'Justificatif de domicile', 'Contrat de bail ou titre de propriété (si applicable)'],
  ARRAY['Créer un compte sur le portail de la Direction Générale des Impôts.', 'Déposer la demande d''identifiant fiscal en ligne ou en centre.', 'Recevoir l''IF par courrier ou le télécharger depuis le portail.', 'Conserver l''identifiant pour vos démarches bancaires et immobilières.'],
  'receipt_long_outlined',
  'https://www.tax.gov.ma/'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO procedures (
  slug, title, summary, category, category_label, estimated_duration,
  documents, steps, icon_key, official_url
) VALUES (
  'cnss-registration',
  'Affiliation CNSS',
  'Affiliation à la Caisse Nationale de Sécurité Sociale pour les salariés et employeurs au Maroc.',
  'sejour',
  'Séjour',
  '2 à 4 semaines',
  ARRAY['CIN ou carte de séjour de l''employé', 'Contrat de travail signé', 'Identifiant fiscal de l''employeur', 'Registre de commerce (si applicable)'],
  ARRAY['L''employeur crée un compte employeur sur le portail CNSS.', 'Déclarer le salarié et transmettre le contrat de travail.', 'Obtenir le numéro d''immatriculation CNSS du salarié.', 'Conserver l''attestation pour les démarches médicales et retraite.'],
  'work_outline',
  'https://www.cnss.ma/'
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours
) VALUES (
  'place-majorelle',
  'Jardin Majorelle',
  'Marrakech',
  'jardin',
  'Jardin',
  'Gueliz',
  '€€€',
  true,
  '#2D6A4F',
  'Jardin botanique emblématique créé par Jacques Majorelle, célèbre pour son bleu Majorelle et ses collections de cactus.',
  ARRAY['Réservez vos billets en ligne pour éviter la file d''attente.', 'Portez des chaussures confortables — le jardin se parcourt à pied.', 'Le musée Berbère sur place mérite une visite de 30 minutes.'],
  'Tôt le matin, avant 10h',
  'https://maps.google.com/?q=Jardin+Majorelle+Marrakech',
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours
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
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours
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
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours
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
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours
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
  NULL
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours
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
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours
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
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours
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
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours
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
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours
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
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours
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
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours
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
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours
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
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours
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
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours
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
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  ARRAY[]::text[],
  ARRAY[]::text[],
  ARRAY[]::text[],
  NULL
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-taxi-marrakech',
  'Course de taxi',
  'Marrakech',
  'transport',
  'Transport',
  20,
  50,
  30,
  'trajet court en ville',
  'Trajet en petit taxi dans le centre ou entre Gueliz et la Médina, compteur allumé.',
  ARRAY['Distance et trafic', 'Compteur vs forfait négocié', 'Heure de pointe et événements'],
  ARRAY['Compteur éteint ou refus de l''allumer', 'Prix annoncé avant le départ sans justification', 'Refus de prendre une course courte'],
  ARRAY['Insistez sur le compteur — c''est la loi.', 'Aéroport-centre : comptez 70 à 100 MAD en forfait.', 'Négociez le forfait avant de monter si le compteur est refusé.'],
  'local_taxi_outlined',
  'Grille taxi Marrakech 2024',
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-restaurant-marrakech',
  'Repas au restaurant',
  'Marrakech',
  'foodAndCafes',
  'Restauration & cafés',
  60,
  120,
  90,
  'par personne',
  'Repas dans un restaurant moyen gamme en ville ou en Médina, hors adresses premium des palaces.',
  ARRAY['Quartier (Médina vs Gueliz)', 'Type de cuisine et standing', 'Boissons et desserts en sus'],
  ARRAY['Addition sans menu ni prix affichés', 'Suppléments « touristiques » non annoncés', 'Couverts ou pain facturés sans prévenir'],
  ARRAY['Le menu du jour à midi est souvent le meilleur rapport qualité-prix.', 'Demandez si l''eau et le pain sont inclus.', 'Les adresses de la place Jemaa el-Fna sont 30 à 50 % plus chères.'],
  'restaurant_outlined',
  NULL,
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-cafe-marrakech',
  'Café ou jus d''orange',
  'Marrakech',
  'foodAndCafes',
  'Restauration & cafés',
  10,
  25,
  15,
  'par boisson',
  'Café noir ou jus d''orange pressé dans un café de quartier.',
  ARRAY['Emplacement (rue vs terrasse touristique)', 'Type de boisson (café local vs importé)', 'Service à table ou au comptoir'],
  ARRAY['Prix non affiché sur la carte', 'Addition surprise pour le service ou la terrasse', 'Jus d''orange facturé comme « fraîchement pressé premium »'],
  ARRAY['Demandez le prix avant de commander.', 'Un café en terrasse touristique peut atteindre 25 à 30 MAD.', 'Préférez les cafés fréquentés par les locaux.'],
  'coffee_outlined',
  NULL,
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-groceries-weekly-marrakech',
  'Panier courses essentiel',
  'Marrakech',
  'groceries',
  'Courses & épicerie',
  250,
  400,
  320,
  'par personne / semaine',
  'Courses de base pour une personne : pain, lait, œufs, fruits, légumes, riz ou pâtes, huile.',
  ARRAY['Enseigne (Marjane, Carrefour, souk)', 'Produits locaux vs importés', 'Promotions et saison des fruits'],
  ARRAY['Prix au kilo non affiché au souk', 'Balance « gonflée » sur les étals', 'Produits importés vendus comme locaux'],
  ARRAY['Comparez le prix au kilo, pas à l''unité.', 'Les marchés du matin offrent les meilleurs prix sur les légumes.', 'Les marques locales sont souvent 30 % moins chères.'],
  'shopping_basket_outlined',
  'Vérifié en Marjane Gueliz, juin 2025',
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-mobile-marrakech',
  'Forfait mobile',
  'Marrakech',
  'services',
  'Services',
  80,
  150,
  100,
  'par mois',
  'Forfait prépayé ou abonnement mobile avec data et appels locaux.',
  ARRAY['Opérateur (Maroc Telecom, Orange, Inwi)', 'Volume de data inclus', 'Engagement ou recharge libre'],
  ARRAY['Recharge via intermédiaire non officiel', 'Forfait « tout illimité » trop beau pour être vrai', 'SIM vendue bien au-dessus du prix boutique'],
  ARRAY['Achetez votre SIM en boutique officielle.', 'Comparez les offres 30 Go — elles se valent souvent.', 'Conservez le reçu de recharge.'],
  'phone_android_outlined',
  NULL,
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-bahia-marrakech',
  'Entrée monument',
  'Marrakech',
  'tourism',
  'Tourisme',
  50,
  80,
  70,
  'par personne',
  'Entrée à un monument majeur de la Médina, ex. Palais de la Bahia.',
  ARRAY['Monument et circuit proposé', 'Tarif résident vs visiteur étranger', 'Guide audio ou accompagnateur en option'],
  ARRAY['Billet vendu par un « guide » sans guichet officiel', 'Prix gonflé pour un « accès privilégié »', 'Photo obligatoire facturée en supplément'],
  ARRAY['Achetez toujours au guichet officiel.', 'Vérifiez le tarif affiché à l''entrée.', 'Certains monuments ferment tôt — prévoyez le matin.'],
  'account_balance_outlined',
  'Tarif Palais Bahia, 2025',
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-guide-medina-marrakech',
  'Guide médina demi-journée',
  'Marrakech',
  'tourism',
  'Tourisme',
  200,
  400,
  300,
  'pour 1 à 4 personnes',
  'Guide agréé ou expérimenté pour une visite de la Médina d''environ 3 heures.',
  ARRAY['Guide agréé vs auto-proclamé', 'Taille du groupe', 'Inclusion de commissions dans les souks'],
  ARRAY['Guide non sollicité qui vous suit', 'Visite « gratuite » menant à des boutiques partenaires', 'Prix final différent du tarif annoncé'],
  ARRAY['Fixez le prix et la durée avant de partir.', 'Refusez les guides insistants à la sortie des riads.', 'Un bon guide ne vous force pas à acheter.'],
  'tour_outlined',
  NULL,
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-juice-jemaa-marrakech',
  'Jus d''orange — place Jemaa el-Fna',
  'Marrakech',
  'tourism',
  'Tourisme',
  40,
  80,
  50,
  'par verre',
  'Jus d''orange pressé sur la place Jemaa el-Fna — nettement au-dessus du prix normal ailleurs en ville (10 – 25 MAD).',
  ARRAY['Emplacement touristique premium', 'Absence d''affichage des prix', 'Pression commerciale et spectacle ambiant'],
  ARRAY['Pas de prix affiché avant la commande', 'Vendeur insistant ou « cadeau » suivi d''une addition', 'Verre facturé 40 MAD ou plus'],
  ARRAY['Demandez le prix avant — refusez si > 25 MAD.', 'Achetez dans un café de rue adjacent à la place.', 'Payez exactement, sans pourboire forcé.'],
  'warning_amber_outlined',
  NULL,
  true,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-rent-marrakech',
  'Studio en centre-ville',
  'Marrakech',
  'housing',
  'Logement',
  3500,
  6000,
  4500,
  'par mois',
  'Location mensuelle d''un studio meublé en Gueliz ou périphérie proche.',
  ARRAY['Quartier (Gueliz, Hivernage, périphérie)', 'Meublé vs vide, charges incluses ou non', 'Durée du bail et saison'],
  ARRAY['Caution demandée sans contrat écrit', 'Photos ne correspondant pas au logement', 'Propriétaire pressant pour un paiement cash immédiat'],
  ARRAY['Visitez toujours avant de signer.', 'Les charges (eau, électricité) sont souvent en sus.', 'Un dépôt de garantie d''un mois est la norme.'],
  'apartment_outlined',
  NULL,
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-taxi-casablanca',
  'Course de taxi',
  'Casablanca',
  'transport',
  'Transport',
  25,
  60,
  35,
  'trajet court en ville',
  'Trajet en petit taxi dans le centre de Casablanca.',
  ARRAY['Distance et embouteillages', 'Compteur vs forfait', 'Trajet de jour vs nuit'],
  ARRAY['Compteur non allumé', 'Forfait exorbitant pour un trajet court', 'Détour non justifié'],
  ARRAY['Les taxis rouges sont omniprésents — insistez sur le compteur.', 'Aéroport-centre : comptez 250 à 350 MAD selon le trafic.', 'Utilisez une app de VTC pour comparer le prix.'],
  'local_taxi_outlined',
  NULL,
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-restaurant-casablanca',
  'Repas au restaurant',
  'Casablanca',
  'foodAndCafes',
  'Restauration & cafés',
  70,
  150,
  110,
  'par personne',
  'Repas dans un restaurant moyen gamme à Casablanca, hors zone premium.',
  ARRAY['Quartier (Maarif, centre, Corniche)', 'Type de cuisine', 'Service et standing'],
  ARRAY['Addition sans détail des plats', 'Frais de service non annoncés', 'Menu uniquement en anglais avec prix gonflés'],
  ARRAY['Le Marché Central offre d''excellents repas à prix doux.', 'Les adresses de la Corniche sont 20 à 30 % plus chères.', 'Vérifiez si le service est inclus.'],
  'restaurant_outlined',
  NULL,
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-cafe-casablanca',
  'Café ou jus d''orange',
  'Casablanca',
  'foodAndCafes',
  'Restauration & cafés',
  12,
  28,
  18,
  'par boisson',
  'Café ou jus frais dans un café de quartier à Casablanca.',
  ARRAY['Quartier (centre vs banlieue)', 'Terrasse ou intérieur', 'Type de boisson'],
  ARRAY['Prix non affiché', 'Supplément terrasse non annoncé', 'Addition arrondie « pour le change »'],
  ARRAY['Les cafés du centre-ville sont légèrement plus chers.', 'Un café en Corniche peut dépasser 25 MAD.', 'Demandez la carte avec les prix.'],
  'coffee_outlined',
  NULL,
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-groceries-weekly-casablanca',
  'Panier courses essentiel',
  'Casablanca',
  'groceries',
  'Courses & épicerie',
  280,
  450,
  360,
  'par personne / semaine',
  'Courses de base pour une personne en grande surface ou marché.',
  ARRAY['Enseigne et emplacement', 'Produits importés', 'Promotions hebdomadaires'],
  ARRAY['Prix barré fictif en promotion', 'Produits périmés en rayon', 'Poids incorrect au marché'],
  ARRAY['Casablanca est en moyenne 10 % plus chère que Marrakech.', 'Les marchés de gros du matin sont avantageux.', 'Comparez le prix au litre ou au kilo.'],
  'shopping_basket_outlined',
  'Vérifié en Carrefour Maarif, juin 2025',
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-haircut-casablanca',
  'Coupe cheveux homme',
  'Casablanca',
  'services',
  'Services',
  40,
  80,
  50,
  'par coupe',
  'Coupe cheveux dans un salon de quartier standard.',
  ARRAY['Quartier et standing du salon', 'Coupe simple vs shampoing inclus', 'Prestataire indépendant vs salon chaîne'],
  ARRAY['Prix annoncé puis augmenté en caisse', 'Produits « obligatoires » ajoutés sans demande', 'Pas de prix affiché à l''entrée'],
  ARRAY['Demandez le tarif avant de vous asseoir.', 'Les salons de la Corniche facturent 50 % de plus.', 'Un pourboire de 5 à 10 MAD est apprécié, pas obligatoire.'],
  'content_cut_outlined',
  NULL,
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-museum-casablanca',
  'Entrée musée',
  'Casablanca',
  'tourism',
  'Tourisme',
  20,
  40,
  30,
  'par personne',
  'Entrée à un musée municipal, ex. Villa des Arts ou Musée du Judaïsme.',
  ARRAY['Musée et exposition temporaire', 'Tarif réduit pour résidents', 'Journées portes ouvertes'],
  ARRAY['Billet vendu par un intermédiaire', 'Visite « privée » facturée en supplément sans valeur', 'Prix différent du guichet officiel'],
  ARRAY['Vérifiez les horaires — certains ferment le lundi.', 'Certains musées sont gratuits le premier dimanche du mois.', 'Achetez au guichet, jamais dans la rue.'],
  'museum_outlined',
  NULL,
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-rent-casablanca',
  'Studio en centre-ville',
  'Casablanca',
  'housing',
  'Logement',
  4500,
  7500,
  5500,
  'par mois',
  'Location mensuelle d''un studio meublé en centre ou Maarif.',
  ARRAY['Quartier (Maarif, Gauthier, Ain Sebaâ)', 'Meublé, charges, parking', 'État du logement et équipements'],
  ARRAY['Annonce trop belle pour le prix affiché', 'Refus de visite avant paiement', 'Contrat uniquement verbal'],
  ARRAY['Casablanca est la ville la plus chère pour le logement.', 'Les quartiers comme Ain Sebaâ sont plus abordables.', 'Vérifiez les charges avant de signer.'],
  'apartment_outlined',
  NULL,
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-taxi-rabat',
  'Course de taxi',
  'Rabat',
  'transport',
  'Transport',
  20,
  45,
  28,
  'trajet court en ville',
  'Trajet en petit taxi dans le centre de Rabat.',
  ARRAY['Distance (Rabat est compacte)', 'Trajet vers Salé', 'Compteur vs forfait'],
  ARRAY['Compteur non utilisé', 'Supplément Salé non annoncé', 'Refus de course courte'],
  ARRAY['Les trajets en centre sont souvent courts et peu chers.', 'Vers Salé, comptez un supplément de 15 à 20 MAD.', 'Insistez sur le compteur.'],
  'local_taxi_outlined',
  NULL,
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-restaurant-rabat',
  'Repas au restaurant',
  'Rabat',
  'foodAndCafes',
  'Restauration & cafés',
  65,
  130,
  95,
  'par personne',
  'Repas dans un restaurant moyen gamme à Rabat ou Agdal.',
  ARRAY['Quartier (Agdal, Hassan, centre)', 'Standing et type de cuisine', 'Clientèle locale vs touristique'],
  ARRAY['Addition gonflée près des sites touristiques', 'Plats du jour à prix « spécial »', 'Service non annoncé ajouté en fin de repas'],
  ARRAY['Le quartier Agdal concentre de bonnes adresses abordables.', 'Rabat est globalement moins chère que Casablanca.', 'Le menu du jour reste le meilleur repère.'],
  'restaurant_outlined',
  NULL,
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-groceries-weekly-rabat',
  'Panier courses essentiel',
  'Rabat',
  'groceries',
  'Courses & épicerie',
  260,
  420,
  340,
  'par personne / semaine',
  'Courses de base pour une personne en grande surface ou marché.',
  ARRAY['Enseigne et quartier', 'Produits locaux vs importés', 'Saison des fruits et légumes'],
  ARRAY['Prix au kilo flou au marché', 'Produits vendus à l''unité plus chers qu''au kilo', 'Étal sans balance visible'],
  ARRAY['Le marché de Hay Riad est compétitif le samedi matin.', 'Comparez Marjane et les marchés de quartier.', 'Les produits de saison sont toujours moins chers.'],
  'shopping_basket_outlined',
  'Vérifié en Marjane Agdal, juin 2025',
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-doctor-rabat',
  'Consultation médecin',
  'Rabat',
  'services',
  'Services',
  200,
  400,
  250,
  'par consultation',
  'Consultation chez un médecin généraliste en cabinet privé.',
  ARRAY['Spécialité et réputation', 'Cabinet vs clinique privée', 'Urgence ou horaire décalé'],
  ARRAY['Frais cachés pour examens non demandés', 'Facturation sans reçu', 'Orientation vers une clinique partenaire sans motif'],
  ARRAY['Demandez le tarif à la prise de rendez-vous.', 'Les cliniques privées sont 30 à 50 % plus chères.', 'Conservez tous les reçus pour remboursement.'],
  'local_hospital_outlined',
  NULL,
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-rent-rabat',
  'Studio en centre-ville',
  'Rabat',
  'housing',
  'Logement',
  3200,
  5500,
  4200,
  'par mois',
  'Location mensuelle d''un studio meublé à Agdal ou centre-ville.',
  ARRAY['Quartier (Agdal, Hay Riad, Hassan)', 'Proximité des administrations', 'Meublé et charges'],
  ARRAY['Loyer demandé en cash sans quittance', 'Logement non conforme aux photos', 'Bail non enregistré'],
  ARRAY['Hay Riad et Agdal sont les quartiers les plus demandés.', 'La proximité des administrations fait grimper les prix.', 'Négociez les charges avant signature.'],
  'apartment_outlined',
  NULL,
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-ctm-bus',
  'Bus CTM inter-villes',
  'National',
  'transport',
  'Transport',
  80,
  150,
  110,
  'par trajet',
  'Trajet en bus CTM entre grandes villes, ex. Marrakech–Casablanca ou Rabat–Fès.',
  ARRAY['Distance et liaison', 'Horaire (week-end plus demandé)', 'Réservation en ligne vs guichet'],
  ARRAY['Billet revendu par un intermédiaire à prix majoré', 'Bus « CTM » non officiel', 'Supplément bagage non annoncé'],
  ARRAY['Réservez sur ctm.ma ou au guichet officiel.', 'Les départs matinaux sont moins chargés.', 'Arrivez 20 minutes avant le départ.'],
  'directions_bus_outlined',
  'Tarifs CTM, juin 2025',
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-pressing-national',
  'Pressing (chemise)',
  'National',
  'services',
  'Services',
  15,
  30,
  20,
  'par chemise',
  'Nettoyage à sec d''une chemise en pressing standard.',
  ARRAY['Ville et quartier', 'Type de tissu', 'Délai express'],
  ARRAY['Prix doublé pour « tissu délicat » non justifié', 'Supplément express non annoncé', 'Ticket perdu facturé comme perte'],
  ARRAY['Demandez le tarif par pièce avant de déposer.', 'Les pressings de centre-ville sont 20 % plus chers.', 'Vérifiez le ticket de dépôt.'],
  'local_laundry_service_outlined',
  NULL,
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-utilities-national',
  'Charges eau + électricité',
  'National',
  'housing',
  'Logement',
  200,
  500,
  350,
  'par mois (studio)',
  'Facture mensuelle combinée eau et électricité pour un studio.',
  ARRAY['Consommation (climatisation en été)', 'Tarif ONEE et contrat au nom du locataire', 'Ancienneté de l''installation'],
  ARRAY['Facture au nom du propriétaire sans détail', 'Montant fixe « forfait charges » opaque', 'Compteur non vérifié à l''entrée'],
  ARRAY['Demandez une facture au nom du locataire si possible.', 'La climatisation peut doubler la facture en été.', 'Relevez le compteur à l''entrée et à la sortie.'],
  'bolt_outlined',
  NULL,
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  'price-khobz-national',
  'Pain khobz',
  'National',
  'groceries',
  'Courses & épicerie',
  1,
  2,
  1,
  'par unité',
  'Pain khobz traditionnel vendu en boulangerie ou four communal.',
  ARRAY['Type de pain (khobz, batbout, msemen)', 'Four communal vs boulangerie', 'Ville (léger écart possible)'],
  ARRAY['Pain vendu au-delà du prix affiché à la boulangerie', 'Vendeur ambulant sans prix visible', 'Pain rassis vendu comme frais'],
  ARRAY['Le khobz est à prix réglementé — 1 à 2 MAD.', 'Achetez tôt le matin pour le pain le plus frais.', 'Le four communal est souvent le moins cher.'],
  'bakery_dining_outlined',
  'Prix réglementé, 2025',
  false,
  '2025-07-11T23:00:00.000Z'
) ON CONFLICT (slug) DO NOTHING;

COMMIT;
