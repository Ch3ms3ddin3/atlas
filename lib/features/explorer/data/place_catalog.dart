import 'package:flutter/material.dart';

import '../domain/models/place_models.dart';

/// Catalogue statique de lieux utiles — sans backend ni API cartographique.
abstract final class PlaceCatalog {
  static const guides = <PlaceGuide>[
    PlaceGuide(
      id: 'place-majorelle',
      name: 'Jardin Majorelle',
      cityName: 'Marrakech',
      category: PlaceCategory.jardin,
      categoryLabel: 'Jardin',
      neighborhood: 'Gueliz',
      priceLevel: '€€€',
      isEditorsPick: true,
      imageColor: Color(0xFF2D6A4F),
      summary:
          'Jardin botanique emblématique créé par Jacques Majorelle, '
          'célèbre pour son bleu Majorelle et ses collections de cactus.',
      bestTimeToVisit: 'Tôt le matin, avant 10h',
      mapsUrl: 'https://maps.google.com/?q=Jardin+Majorelle+Marrakech',
      latitude: 31.6415,
      longitude: -8.003,
      practicalTips: [
        'Réservez vos billets en ligne pour éviter la file d\'attente.',
        'Portez des chaussures confortables — le jardin se parcourt à pied.',
        'Le musée Berbère sur place mérite une visite de 30 minutes.',
      ],
    ),
    PlaceGuide(
      id: 'place-bahia',
      name: 'Palais de la Bahia',
      cityName: 'Marrakech',
      category: PlaceCategory.monument,
      categoryLabel: 'Monument',
      neighborhood: 'Médina',
      priceLevel: '€€',
      isEditorsPick: false,
      imageColor: Color(0xFFC4654A),
      summary:
          'Palais viziral du XIXe siècle : enfilade de patios, zellige et '
          'cèdre sculpté — la visite d\'intérieur la plus claire pour '
          'comprendre l\'architecture palatiale marrakchie.',
      bestTimeToVisit: 'À l\'ouverture ; vérifier les horaires le jour même',
      address: 'Rue Riad Zitoun el Jedid, Médina, Marrakech',
      latitude: 31.621420,
      longitude: -7.982689,
      website: 'https://e-services.minculture.gov.ma/fr/tickets/palais-bahia',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.621420,-7.982689',
      openingHours: PlaceOpeningHours(
        note:
            'Horaires variables — vérifier sur place le jour de la visite '
            '(souvent ~09:00–17:00 ; plus courts pendant le Ramadan). '
            'Tarif adulte étranger : 100 MAD (e-services Ministère de la Culture).',
      ),
      practicalTips: [
        'Arrivez à l\'ouverture : la lumière rase des patios et la file '
            'sont meilleures avant l\'arrivée des groupes.',
      ],
    ),
    PlaceGuide(
      id: 'place-koutoubia',
      name: 'Mosquée de la Koutoubia',
      cityName: 'Marrakech',
      category: PlaceCategory.monument,
      categoryLabel: 'Monument',
      neighborhood: 'Médina',
      priceLevel: '€',
      isEditorsPick: false,
      imageColor: Color(0xFF8B6B4A),
      summary:
          'Minaret almohade qui oriente toute la Médina — landmark à lire '
          'depuis l\'extérieur et les jardins, pas comme une visite intérieure.',
      bestTimeToVisit: 'Fin de journée pour la lumière ; éviter le pic du vendredi midi',
      address: 'Rue Koutoubia, Médina, Marrakech',
      latitude: 31.623751,
      longitude: -7.993358,
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.623751,-7.993358',
      openingHours: PlaceOpeningHours(
        note:
            'Mosquée en activité : pas de billetterie pour l\'extérieur. '
            'Esplanade et jardins libres d\'accès. '
            'Salle de prière réservée aux musulmans.',
      ),
      practicalTips: [
        'Pour les non-musulmans : restez sur l\'esplanade et les jardins ; '
            'n\'essayez pas d\'entrer dans la salle de prière.',
      ],
    ),
    PlaceGuide(
      id: 'place-medersa-ben-youssef',
      name: 'Médersa Ben Youssef',
      cityName: 'Marrakech',
      category: PlaceCategory.monument,
      categoryLabel: 'Monument',
      neighborhood: 'Médina',
      priceLevel: '€€',
      isEditorsPick: true,
      imageColor: Color(0xFF5C4A3A),
      summary:
          'Ancienne école coranique restaurée : patio de marbre, stucs et '
          'cellules d\'étudiants — le plus fort moment d\'architecture '
          'savante de Marrakech.',
      bestTimeToVisit: 'Dès 9h00, avant l\'affluence',
      address: 'Rue Assouel / Passage Ecole Ben Youssef, Médina, Marrakech',
      latitude: 31.631984,
      longitude: -7.986036,
      website: 'https://www.medersabenyoussef.ma/',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.631984,-7.986036',
      openingHours: PlaceOpeningHours(
        note:
            'Tous les jours 09:00–19:00 ; Ramadan 09:00–16:30 '
            '(site officiel). Billets sur place '
            '(billetterie en ligne en maintenance). '
            'Adulte étranger : 50 MAD.',
        entries: [
          PlaceHoursEntry(dayLabel: 'Tous les jours', hoursLabel: '09:00–19:00'),
          PlaceHoursEntry(dayLabel: 'Ramadan', hoursLabel: '09:00–16:30'),
        ],
      ),
      practicalTips: [
        'Entrez dès 9h : la cour est encore vide et la lumière révèle '
            'le zellige sans la foule de mi-journée.',
      ],
    ),
    PlaceGuide(
      id: 'place-jemaa-el-fna',
      name: 'Place Jemaa el-Fna',
      cityName: 'Marrakech',
      category: PlaceCategory.souk,
      categoryLabel: 'Souk',
      neighborhood: 'Médina',
      priceLevel: '€',
      isEditorsPick: true,
      imageColor: Color(0xFF8B4513),
      summary:
          'Cœur battant de la Médina — spectacles de rue, étals de nourriture '
          'et artisanat dès la tombée du jour.',
      bestTimeToVisit: 'Fin d\'après-midi et soirée',
      mapsUrl: 'https://maps.google.com/?q=Jemaa+el-Fna+Marrakech',
      latitude: 31.6258,
      longitude: -7.9891,
      practicalTips: [
        'Négociez les prix dans les souks — c\'est la coutume.',
        'Goûtez les jus d\'orange frais des étals de la place.',
        'Restez vigilant sur vos affaires dans la foule du soir.',
      ],
    ),
    PlaceGuide(
      id: 'place-ysl-museum',
      name: 'Musée Yves Saint Laurent Marrakech',
      cityName: 'Marrakech',
      category: PlaceCategory.musee,
      categoryLabel: 'Musée',
      neighborhood: 'Guéliz',
      priceLevel: '€€€',
      isEditorsPick: false,
      imageColor: Color(0xFF1A1A2E),
      summary:
          'Musée dédié à l\'œuvre d\'Yves Saint Laurent, à deux pas de '
          'Majorelle — mode, scénographie et héritage, hors de la boucle '
          'monuments de la Médina.',
      bestTimeToVisit: 'Hors mercredi ; réserver en ligne',
      address: 'Rue Yves Saint Laurent, Guéliz, Marrakech',
      latitude: 31.642543,
      longitude: -8.003420,
      website: 'https://www.museeyslmarrakech.com/fr/',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.642543,-8.003420',
      openingHours: PlaceOpeningHours(
        note:
            'Ouvert tous les jours sauf mercredi, 10:00–18:30 '
            '(dernier accès 18:00). Horaires Ramadan plus courts — '
            'voir le site officiel. Billets uniquement sur '
            'tickets.jardinmajorelle.com.',
        entries: [
          PlaceHoursEntry(dayLabel: 'Lundi', hoursLabel: '10:00–18:30'),
          PlaceHoursEntry(dayLabel: 'Mardi', hoursLabel: '10:00–18:30'),
          PlaceHoursEntry(dayLabel: 'Mercredi', hoursLabel: 'Fermé'),
          PlaceHoursEntry(dayLabel: 'Jeudi', hoursLabel: '10:00–18:30'),
          PlaceHoursEntry(dayLabel: 'Vendredi', hoursLabel: '10:00–18:30'),
          PlaceHoursEntry(dayLabel: 'Samedi', hoursLabel: '10:00–18:30'),
          PlaceHoursEntry(dayLabel: 'Dimanche', hoursLabel: '10:00–18:30'),
        ],
      ),
      practicalTips: [
        'Fermé le mercredi ; n\'achetez des billets que sur '
            'tickets.jardinmajorelle.com (QR officiel).',
      ],
    ),
    PlaceGuide(
      id: 'place-tombeaux-saadiens',
      name: 'Tombeaux Saadiens',
      cityName: 'Marrakech',
      category: PlaceCategory.monument,
      categoryLabel: 'Monument',
      neighborhood: 'Kasbah',
      priceLevel: '€€',
      isEditorsPick: false,
      imageColor: Color(0xFF6B5A4A),
      summary:
          'Nécropole saadienne redécouverte au XXe siècle : marbre, zellige '
          'et chambre des Douze Colonnes dans un enclos discret de la Kasbah.',
      bestTimeToVisit: 'Tôt le matin ; vérifier les horaires le jour même',
      address: 'Rue de la Kasbah, Kasbah, Marrakech',
      latitude: 31.617259,
      longitude: -7.988555,
      website:
          'https://e-services.minculture.gov.ma/fr/tickets/tombeaux-saadiens',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.617259,-7.988555',
      openingHours: PlaceOpeningHours(
        note:
            'Horaires variables — vérifier sur place le jour de la visite '
            '(souvent ~09:00–17:00 ; plus courts pendant le Ramadan). '
            'Tarif adulte étranger : 100 MAD (e-services Ministère de la Culture). '
            'Possible gêne près de la mosquée de la Kasbah le vendredi midi.',
      ),
      practicalTips: [
        'Cherchez le passage étroit le long de la mosquée de la Kasbah — '
            'l\'entrée n\'est presque pas signalée.',
      ],
    ),
    PlaceGuide(
      id: 'place-el-badi',
      name: 'Palais El Badi',
      cityName: 'Marrakech',
      category: PlaceCategory.monument,
      categoryLabel: 'Monument',
      neighborhood: 'Kasbah',
      priceLevel: '€€',
      isEditorsPick: false,
      imageColor: Color(0xFF9A7B5A),
      summary:
          'Ruines saadiennes à ciel ouvert : l\'échelle du pouvoir du XVIe '
          'siècle, stork nests inclus — contraste total avec les salons '
          'intacts de la Bahia.',
      bestTimeToVisit: 'Matinée ; prévoir soleil et eau',
      address: 'Ksibat Nhass / Derb Touareg Berrima, Kasbah, Marrakech',
      latitude: 31.618966,
      longitude: -7.985704,
      website: 'https://e-services.minculture.gov.ma/fr/tickets/palais-badii',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.618966,-7.985704',
      openingHours: PlaceOpeningHours(
        note:
            'Horaires variables — vérifier sur place le jour de la visite '
            '(souvent ~09:00–17:00 ; plus courts pendant le Ramadan). '
            'Tarif adulte étranger : 100 MAD (e-services Ministère de la Culture).',
      ),
      practicalTips: [
        'Combinez avec les Tombeaux Saadiens le même demi-journée Kasbah ; '
            'prévoyez chapeau et eau.',
      ],
    ),
    PlaceGuide(
      id: 'place-les-bains-marrakech',
      name: 'Les Bains de Marrakech',
      cityName: 'Marrakech',
      category: PlaceCategory.hammam,
      categoryLabel: 'Hammam',
      neighborhood: 'Kasbah',
      priceLevel: '€€€',
      isEditorsPick: true,
      imageColor: Color(0xFF5C7A8A),
      summary:
          'Spa-hammam emblématique de la Kasbah — rituels marocains '
          'dans un riad intimiste près de Bab Agnaou.',
      bestTimeToVisit: 'Réservez en matinée ou en fin d\'après-midi',
      address: '2 Derb Sedra, Bab Agnaou, Marrakech',
      latitude: 31.617286,
      longitude: -7.990510,
      phone: '+212524381428',
      website: 'https://lesbainsdemarrakech.com',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.617286,-7.990510',
      practicalTips: [
        'Réservez à l\'avance — l\'établissement est très demandé.',
        'Prévoyez 1h30 à 2h pour un rituel hammam + massage.',
        'L\'adresse est dans un derb de la Kasbah : suivez le GPS jusqu\'à Bab Agnaou.',
      ],
    ),
    PlaceGuide(
      id: 'place-hammam-de-la-rose',
      name: 'Hammam de la Rose',
      cityName: 'Marrakech',
      category: PlaceCategory.hammam,
      categoryLabel: 'Hammam',
      neighborhood: 'Dar El Bacha',
      priceLevel: '€€€',
      isEditorsPick: false,
      imageColor: Color(0xFF7A5C6A),
      summary:
          'Hammam-spa soigné près de Dar El Bacha — cadre calme '
          'pour un rituel gommage et détente en Médina.',
      bestTimeToVisit: 'Sur réservation, hors heure de pointe',
      address: '130 Dar El Bacha, Marrakech',
      latitude: 31.631655,
      longitude: -7.991533,
      phone: '+212524444769',
      website: 'https://www.hammamdelarose.com',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.631655,-7.991533',
      practicalTips: [
        'Réservez avant de vous déplacer dans la Médina.',
        'Idéal après une matinée autour de Dar El Bacha / Mouassine.',
        'Demandez les créneaux femmes / mixtes selon votre besoin.',
      ],
    ),
    PlaceGuide(
      id: 'place-heritage-spa',
      name: 'Heritage Spa',
      cityName: 'Marrakech',
      category: PlaceCategory.hammam,
      categoryLabel: 'Hammam',
      neighborhood: 'Bab Doukkala',
      priceLevel: '€€€',
      isEditorsPick: false,
      imageColor: Color(0xFF4A6670),
      summary:
          'Spa de Médina à Bab Doukkala — hammam et massages '
          'dans une adresse discrète d\'Arset Aouzal.',
      bestTimeToVisit: 'Fin de matinée ou après-midi',
      address: '40 Arset Aouzal, Marrakech',
      latitude: 31.630931,
      longitude: -7.994706,
      phone: '+212524384333',
      website: 'https://www.heritagespamarrakech.com',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.630931,-7.994706',
      practicalTips: [
        'Confirmez le site « Heritage Spa 40 » (Arset Aouzal) à la réservation.',
        'Arrivez quelques minutes en avance pour le vestiaire.',
        'Pratique si vous explorez Bab Doukkala / Guéliz côté Médina.',
      ],
    ),
    PlaceGuide(
      id: 'place-hammam-place-des-epices',
      name: 'Hammam Place des Épices',
      cityName: 'Marrakech',
      category: PlaceCategory.hammam,
      categoryLabel: 'Hammam',
      neighborhood: 'Rahba Lakdima',
      priceLevel: '€€',
      isEditorsPick: false,
      imageColor: Color(0xFF8A6B4A),
      summary:
          'Spa-hammam au cœur de la Place des Épices — pause bien-être '
          'après les souks de Rahba Lakdima.',
      bestTimeToVisit: 'Après une visite de la place, sur créneau réservé',
      address: '156–157 Derb Aarjane, Rahba Lakdima, Marrakech',
      latitude: 31.628455,
      longitude: -7.987441,
      phone: '+212524384013',
      website: 'https://spadesepices.com',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.628455,-7.987441',
      practicalTips: [
        'Repère facile : Place des Épices / Rahba Lakdima, puis Derb Aarjane.',
        'Réservez aux heures de forte affluence touristique.',
        'Accès piéton dans la Médina — prévoyez du temps pour vous y rendre.',
      ],
    ),
    PlaceGuide(
      id: 'place-al-fassia-gueliz',
      name: 'Al Fassia Guéliz',
      cityName: 'Marrakech',
      category: PlaceCategory.restaurant,
      categoryLabel: 'Restaurant',
      neighborhood: 'Guéliz',
      priceLevel: '€€€',
      isEditorsPick: true,
      imageColor: Color(0xFF9C4A3C),
      summary:
          'Table marocaine fassi tenue par des femmes depuis 1987 — '
          'référence Guéliz sur le boulevard Zerktouni (pas Aguedal).',
      bestTimeToVisit: 'Sur réservation ; fermé le mardi',
      address: '55 Boulevard Mohamed Zerktouni, Guéliz, Marrakech',
      latitude: 31.635992,
      longitude: -8.013364,
      phone: '+212524437973',
      website: 'https://alfassia.com',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.635992,-8.013364',
      openingHours: PlaceOpeningHours(
        entries: [
          PlaceHoursEntry(dayLabel: 'Lundi', hoursLabel: '17:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Mardi', hoursLabel: 'Fermé'),
          PlaceHoursEntry(dayLabel: 'Mercredi', hoursLabel: '17:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Jeudi', hoursLabel: '17:00–23:00'),
          PlaceHoursEntry(
            dayLabel: 'Vendredi',
            hoursLabel: '12:30–14:30 · 19:00–23:00',
          ),
          PlaceHoursEntry(
            dayLabel: 'Samedi',
            hoursLabel: '12:30–14:30 · 19:00–23:00',
          ),
          PlaceHoursEntry(dayLabel: 'Dimanche', hoursLabel: '17:00–23:00'),
        ],
      ),
      practicalTips: [
        'Réservez la ligne Guéliz (+212 524 43 79 73 / 43 40 60) — '
            'pas le restaurant Aguedal (Route de l\'Ourika).',
        'Confirmez la réservation par téléphone une fois à Marrakech.',
        'Fermé le mardi.',
      ],
    ),
    PlaceGuide(
      id: 'place-amal-gueliz',
      name: 'Restaurant Amal Guéliz',
      cityName: 'Marrakech',
      category: PlaceCategory.restaurant,
      categoryLabel: 'Restaurant',
      neighborhood: 'Guéliz',
      priceLevel: '€',
      isEditorsPick: false,
      imageColor: Color(0xFFC4784A),
      summary:
          'Restaurant social de Guéliz — cuisine marocaine du marché '
          'qui finance la formation culinaire de femmes.',
      bestTimeToVisit: 'Déjeuner en semaine ; réservez le vendredi couscous',
      address: 'Rue Allal Ben Ahmed et Rue Ibn Sina, Guéliz, Marrakech',
      latitude: 31.639072,
      longitude: -8.013756,
      phone: '+212524446896',
      website: 'https://amalnonprofit.org',
      email: 'contact@amalnonprofit.org',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.639072,-8.013756',
      openingHours: PlaceOpeningHours(
        entries: [
          PlaceHoursEntry(dayLabel: 'Lundi', hoursLabel: '12:00–15:30'),
          PlaceHoursEntry(dayLabel: 'Mardi', hoursLabel: '12:00–15:30'),
          PlaceHoursEntry(dayLabel: 'Mercredi', hoursLabel: '12:00–15:30'),
          PlaceHoursEntry(dayLabel: 'Jeudi', hoursLabel: '12:00–15:30'),
          PlaceHoursEntry(dayLabel: 'Vendredi', hoursLabel: '12:00–15:30'),
          PlaceHoursEntry(dayLabel: 'Samedi', hoursLabel: '12:00–15:30'),
          PlaceHoursEntry(dayLabel: 'Dimanche', hoursLabel: 'Fermé'),
        ],
        note: 'Déjeuner uniquement — pas de service du soir en semaine.',
      ),
      practicalTips: [
        'Déjeuner uniquement (lun–sam) ; fermé le dimanche.',
        'Réservez pour le couscous du vendredi et le week-end.',
        'C\'est le centre Guéliz — pas Amal Targa (cours de cuisine).',
      ],
    ),
    PlaceGuide(
      id: 'place-nomad',
      name: 'Nomad',
      cityName: 'Marrakech',
      category: PlaceCategory.restaurant,
      categoryLabel: 'Restaurant',
      neighborhood: 'Médina',
      priceLevel: '€€€',
      isEditorsPick: false,
      imageColor: Color(0xFF6B4F3A),
      summary:
          'Restaurant « Modern Moroccan » sur les toits près de la '
          'Place des Épices — cuisine locale revisitée.',
      bestTimeToVisit: 'Réservez pour le coucher de soleil',
      address: '1 Derb Aarjane, Médina, Marrakech',
      latitude: 31.628593,
      longitude: -7.987530,
      phone: '+212524381609',
      website: 'https://nomadmarrakech.com',
      email: 'info@nomadmarrakech.com',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.628593,-7.987530',
      openingHours: PlaceOpeningHours(
        entries: [
          PlaceHoursEntry(dayLabel: 'Lundi', hoursLabel: '12:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Mardi', hoursLabel: '12:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Mercredi', hoursLabel: '12:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Jeudi', hoursLabel: '12:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Vendredi', hoursLabel: '12:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Samedi', hoursLabel: '12:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Dimanche', hoursLabel: '12:00–23:00'),
        ],
      ),
      practicalTips: [
        'Depuis Jemaa el-Fna, direction Place des Épices ; '
            'demandez au Café des Épices.',
        'Réservez sur nomadmarrakech.com ou au +212 524 38 16 09.',
        'Adresse : 1 Derb Aarjane, Médina.',
      ],
    ),
    PlaceGuide(
      id: 'place-plus61',
      name: 'Plus61',
      cityName: 'Marrakech',
      category: PlaceCategory.restaurant,
      categoryLabel: 'Restaurant',
      neighborhood: 'Guéliz',
      priceLevel: '€€€',
      isEditorsPick: false,
      imageColor: Color(0xFF3D5A4C),
      summary:
          'Bistro contemporain australien / méditerranéen à Guéliz — '
          'plats à partager, produits locaux (aussi connu sous +61).',
      bestTimeToVisit: 'Déjeuner ou dîner en semaine (fermé le dimanche)',
      address: '96 Rue Mohammed el Beqal, Guéliz, Marrakech',
      latitude: 31.635162,
      longitude: -8.015502,
      phone: '+212524207020',
      website: 'https://plus61.com',
      email: 'hello@plus61.com',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.635162,-8.015502',
      openingHours: PlaceOpeningHours(
        entries: [
          PlaceHoursEntry(
            dayLabel: 'Lundi',
            hoursLabel: '12:00–15:00 · 18:30–22:30',
          ),
          PlaceHoursEntry(
            dayLabel: 'Mardi',
            hoursLabel: '12:00–15:00 · 18:30–22:30',
          ),
          PlaceHoursEntry(
            dayLabel: 'Mercredi',
            hoursLabel: '12:00–15:00 · 18:30–22:30',
          ),
          PlaceHoursEntry(
            dayLabel: 'Jeudi',
            hoursLabel: '12:00–15:00 · 18:30–22:30',
          ),
          PlaceHoursEntry(
            dayLabel: 'Vendredi',
            hoursLabel: '12:00–15:00 · 18:30–22:30',
          ),
          PlaceHoursEntry(
            dayLabel: 'Samedi',
            hoursLabel: '12:00–15:00 · 18:30–22:30',
          ),
          PlaceHoursEntry(dayLabel: 'Dimanche', hoursLabel: 'Fermé'),
        ],
      ),
      practicalTips: [
        'Rue Mohammed el Beqal, en face du Cinema Colisée.',
        'Groupes de 6+ : écrivez à hello@plus61.com.',
        'Vérifiez plus61.com/visit pour d\'éventuelles fermetures saisonnières.',
      ],
    ),
    PlaceGuide(
      id: 'place-le-jardin',
      name: 'Le Jardin',
      cityName: 'Marrakech',
      category: PlaceCategory.restaurant,
      categoryLabel: 'Restaurant',
      neighborhood: 'Médina',
      priceLevel: '€€',
      isEditorsPick: false,
      imageColor: Color(0xFF5A7A4A),
      summary:
          'Restaurant-jardin en Médina (Souk Sidi Abdelaziz) — '
          'pause midi ou soir, distinct de l\'hôtel Les Jardins de la Medina.',
      bestTimeToVisit: 'Déjeuner ou dîner ; ouvert toute la journée',
      address: '32 Souk Sidi Abdelaziz, Médina, Marrakech',
      latitude: 31.632074,
      longitude: -7.988806,
      phone: '+212524378295',
      website: 'https://lejardinmarrakech.com',
      email: 'info@lejardinmarrakech.com',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.632074,-7.988806',
      openingHours: PlaceOpeningHours(
        entries: [
          PlaceHoursEntry(dayLabel: 'Lundi', hoursLabel: '10:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Mardi', hoursLabel: '10:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Mercredi', hoursLabel: '10:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Jeudi', hoursLabel: '10:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Vendredi', hoursLabel: '10:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Samedi', hoursLabel: '10:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Dimanche', hoursLabel: '10:00–23:00'),
        ],
      ),
      practicalTips: [
        'Ne confondez pas avec « Les Jardins de la Medina » '
            '(hôtel / Derb Chtouka).',
        '32 Souk Sidi Abdelaziz, Médina.',
        'Réservez au +212 524 37 82 95 ou sur lejardinmarrakech.com.',
      ],
    ),
    PlaceGuide(
      id: 'place-sahbi-sahbi',
      name: 'Sahbi Sahbi',
      cityName: 'Marrakech',
      category: PlaceCategory.restaurant,
      categoryLabel: 'Restaurant',
      neighborhood: 'Guéliz',
      priceLevel: '€€€',
      isEditorsPick: false,
      imageColor: Color(0xFF8A5A3C),
      summary:
          'Cuisine marocaine contemporaine en cuisine ouverte, équipe '
          'de femmes — table Guéliz pensée comme un atelier de recettes '
          'régionales, pas un palace.',
      bestTimeToVisit: 'Dîner sur réservation ; fermé le lundi',
      address: '37 Boulevard El Mansour Eddahbi, Guéliz, Marrakech',
      latitude: 31.634075,
      longitude: -8.014582,
      website: 'https://www.sahbisahbi.com/',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.634075,-8.014582',
      openingHours: PlaceOpeningHours(
        entries: [
          PlaceHoursEntry(dayLabel: 'Lundi', hoursLabel: 'Fermé'),
          PlaceHoursEntry(dayLabel: 'Mardi', hoursLabel: '19:00–01:00'),
          PlaceHoursEntry(dayLabel: 'Mercredi', hoursLabel: '19:00–01:00'),
          PlaceHoursEntry(dayLabel: 'Jeudi', hoursLabel: '19:00–01:00'),
          PlaceHoursEntry(dayLabel: 'Vendredi', hoursLabel: '19:00–01:00'),
          PlaceHoursEntry(dayLabel: 'Samedi', hoursLabel: '19:00–01:00'),
          PlaceHoursEntry(dayLabel: 'Dimanche', hoursLabel: '19:00–01:00'),
        ],
        note: 'Service du soir uniquement (site officiel).',
      ),
      practicalTips: [
        'Réservez : dîner uniquement, mardi–dimanche ; fermé le lundi.',
      ],
    ),
    PlaceGuide(
      id: 'place-grand-cafe-de-la-poste',
      name: 'Le Grand Café de la Poste',
      cityName: 'Marrakech',
      category: PlaceCategory.restaurant,
      categoryLabel: 'Restaurant',
      neighborhood: 'Guéliz',
      priceLevel: '€€€',
      isEditorsPick: false,
      imageColor: Color(0xFF6B5538),
      summary:
          'Brasserie Guéliz d\'époque restaurée — cuisine française / '
          'méditerranéenne dans un décor Studio KO, loin des rooftops Médina.',
      bestTimeToVisit: 'Sur réservation ; vérifier les créneaux du jour',
      address:
          'Angle Boulevard El Mansour Eddahbi et Avenue Imam Malik, '
          'Guéliz, Marrakech',
      latitude: 31.633120,
      longitude: -8.010006,
      phone: '+212524433038',
      website: 'https://www.grandcafedelaposte.restaurant/',
      email: 'contact@grandcafedelaposte.restaurant',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.633120,-8.010006',
      openingHours: PlaceOpeningHours(
        note:
            'Brasserie ouverte petit-déjeuner / déjeuner / dîner — '
            'horaires exacts à confirmer via le site ou la réservation '
            '(grandcafedelaposte.restaurant).',
      ),
      practicalTips: [
        'Réservez sur grandcafedelaposte.restaurant ou au '
            '+212 5 24 43 30 38 ; angle Mansour Eddahbi / Imam Malik.',
      ],
    ),
    PlaceGuide(
      id: 'place-catanzaro',
      name: 'Catanzaro',
      cityName: 'Marrakech',
      category: PlaceCategory.restaurant,
      categoryLabel: 'Restaurant',
      neighborhood: 'Guéliz',
      priceLevel: '€€',
      isEditorsPick: false,
      imageColor: Color(0xFFB85A3A),
      summary:
          'Trattoria familiale Guéliz depuis 1986 — pizzas au feu de bois '
          'et pâtes fraîches, adresse de quartier autant que table touristique.',
      bestTimeToVisit: 'Déjeuner ou dîner ; fermé le dimanche',
      address: 'Rue Tariq Bnou Ziad, Guéliz, Marrakech',
      latitude: 31.634900,
      longitude: -8.010477,
      website: 'https://en.catanzaro.ma/accueil',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.634900,-8.010477',
      openingHours: PlaceOpeningHours(
        entries: [
          PlaceHoursEntry(
            dayLabel: 'Lundi',
            hoursLabel: '12:00–15:00 · 19:00–23:00',
          ),
          PlaceHoursEntry(
            dayLabel: 'Mardi',
            hoursLabel: '12:00–15:00 · 19:00–23:00',
          ),
          PlaceHoursEntry(
            dayLabel: 'Mercredi',
            hoursLabel: '12:00–15:00 · 19:00–23:00',
          ),
          PlaceHoursEntry(
            dayLabel: 'Jeudi',
            hoursLabel: '12:00–15:00 · 19:00–23:00',
          ),
          PlaceHoursEntry(
            dayLabel: 'Vendredi',
            hoursLabel: '12:00–15:00 · 19:00–23:00',
          ),
          PlaceHoursEntry(
            dayLabel: 'Samedi',
            hoursLabel: '12:00–15:00 · 19:00–23:00',
          ),
          PlaceHoursEntry(dayLabel: 'Dimanche', hoursLabel: 'Fermé'),
        ],
      ),
      practicalTips: [
        'Réservez aux heures de pointe ; fermé le dimanche '
            '(site officiel Catanzaro).',
      ],
    ),
    PlaceGuide(
      id: 'place-naranj',
      name: 'Naranj',
      cityName: 'Marrakech',
      category: PlaceCategory.restaurant,
      categoryLabel: 'Restaurant',
      neighborhood: 'Médina',
      priceLevel: '€€',
      isEditorsPick: false,
      imageColor: Color(0xFFC45A3A),
      summary:
          'Cuisine libanaise / levantine en Médina — mezze à partager '
          'et rooftop, alternative claire aux tables marocaines.',
      bestTimeToVisit: 'Déjeuner ou dîner ; réservez le rooftop',
      address: '84 Rue Riad Zitoun el Jdid, Médina, Marrakech',
      latitude: 31.624537,
      longitude: -7.985213,
      phone: '+212671569542',
      website: 'https://naranj.ma/',
      email: 'office@naranj.ma',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.624537,-7.985213',
      openingHours: PlaceOpeningHours(
        note:
            'Horaires officiels signalés autour de 12:30–22:30 — '
            'vérifier le jour même (pages du site parfois Lun–Sam '
            'vs tous les jours).',
      ),
      practicalTips: [
        '84 Rue Riad Zitoun el Jdid ; réservez via naranj.ma '
            'pour le rooftop.',
      ],
    ),
    PlaceGuide(
      id: 'place-la-trattoria',
      name: 'La Trattoria',
      cityName: 'Marrakech',
      category: PlaceCategory.restaurant,
      categoryLabel: 'Restaurant',
      neighborhood: 'Guéliz',
      priceLevel: '€€€€',
      isEditorsPick: false,
      imageColor: Color(0xFF4A6B5A),
      summary:
          'Institution italienne depuis 1974 dans une villa Art déco — '
          'dîner jardin / piscine pour une soirée soignée, pas une '
          'pizza de quartier.',
      bestTimeToVisit: 'Sur réservation ; lundi dîner uniquement',
      address: '179 Rue Mohammed el Beqal, Guéliz, Marrakech',
      latitude: 31.633840,
      longitude: -8.015174,
      phone: '+212524432641',
      website: 'https://www.latrattoriamarrakech.com/',
      email: 'reservation@latrattoriamarrakech.com',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.633840,-8.015174',
      openingHours: PlaceOpeningHours(
        entries: [
          PlaceHoursEntry(dayLabel: 'Lundi', hoursLabel: '18:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Mardi', hoursLabel: '12:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Mercredi', hoursLabel: '12:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Jeudi', hoursLabel: '12:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Vendredi', hoursLabel: '12:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Samedi', hoursLabel: '12:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Dimanche', hoursLabel: '12:00–23:00'),
        ],
      ),
      practicalTips: [
        'Réservez sur latrattoriamarrakech.com ; distinct de Catanzaro '
            '(trattoria de quartier, même ville).',
      ],
    ),
    PlaceGuide(
      id: 'place-dar-moha',
      name: 'Dar Moha',
      cityName: 'Marrakech',
      category: PlaceCategory.restaurant,
      categoryLabel: 'Restaurant',
      neighborhood: 'Médina',
      priceLevel: '€€€€',
      isEditorsPick: false,
      imageColor: Color(0xFF7A4A3A),
      summary:
          'Cuisine marocaine gastronomique dans un riad du quartier '
          'Dar El Bacha — table d\'exception du Chef Moha, hors circuit '
          'palace.',
      bestTimeToVisit: 'Déjeuner ou dîner sur réservation',
      address: '81 Rue Dar El Bacha, Médina, Marrakech',
      latitude: 31.631367,
      longitude: -7.993267,
      phone: '+212524386400',
      website: 'https://darmoha.ma/',
      email: 'restaurant@darmoha.ma',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.631367,-7.993267',
      openingHours: PlaceOpeningHours(
        entries: [
          PlaceHoursEntry(
            dayLabel: 'Tous les jours',
            hoursLabel: '12:00–16:00 · 19:00–23:00',
          ),
        ],
        note: 'Déjeuner 12:00–16:00 ; dîner 19:00–23:00 (site officiel).',
      ),
      practicalTips: [
        'Réservez sur darmoha.ma ou au +212 5 24 38 64 00 ; '
            '81 Rue Dar El Bacha (Médina).',
      ],
    ),
    PlaceGuide(
      id: 'place-bacha-coffee',
      name: 'Bacha Coffee',
      cityName: 'Marrakech',
      category: PlaceCategory.cafe,
      categoryLabel: 'Café',
      neighborhood: 'Médina',
      priceLevel: '€€€',
      isEditorsPick: true,
      imageColor: Color(0xFF6B3A2A),
      summary:
          'Maison de café dans le palais Dar El Bacha — '
          'expérience Arabica patrimoniale (pas un coffee shop de rue).',
      bestTimeToVisit: 'À l\'ouverture (10:00) ; fermé le lundi',
      address: 'Dar El Bacha, Route Sidi Abelaziz, Médina, Marrakech',
      latitude: 31.631521,
      longitude: -7.992561,
      phone: '+212524381293',
      website: 'https://bachacoffee.com/',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.631521,-7.992561',
      openingHours: PlaceOpeningHours(
        entries: [
          PlaceHoursEntry(dayLabel: 'Lundi', hoursLabel: 'Fermé'),
          PlaceHoursEntry(dayLabel: 'Mardi', hoursLabel: '10:00–18:00'),
          PlaceHoursEntry(dayLabel: 'Mercredi', hoursLabel: '10:00–18:00'),
          PlaceHoursEntry(dayLabel: 'Jeudi', hoursLabel: '10:00–18:00'),
          PlaceHoursEntry(dayLabel: 'Vendredi', hoursLabel: '10:00–18:00'),
          PlaceHoursEntry(dayLabel: 'Samedi', hoursLabel: '10:00–18:00'),
          PlaceHoursEntry(dayLabel: 'Dimanche', hoursLabel: '10:00–18:00'),
        ],
      ),
      practicalTips: [
        'Fermé le lundi ; arrivez vers l\'ouverture (10:00) — '
            'files longues, pas de réservation individuelle.',
        'Pin Dar El Bacha / Route Sidi Abelaziz — pas un autre Bacha Coffee '
            'à l\'étranger.',
        'Accès via le complexe muséal Dar El Bacha.',
      ],
    ),
    PlaceGuide(
      id: 'place-simple-specialty-coffee',
      name: 'Simple Specialty Coffee',
      cityName: 'Marrakech',
      category: PlaceCategory.cafe,
      categoryLabel: 'Café',
      neighborhood: 'Médina',
      priceLevel: '€€',
      isEditorsPick: false,
      imageColor: Color(0xFF8B6914),
      summary:
          'Petit comptoir specialty coffee près de Dar El Bacha — '
          'espresso et latte soignés, alternative calme à la file de Bacha.',
      bestTimeToVisit: 'Pause café en journée',
      address: 'Rue Dar El Bacha, Médina, Marrakech',
      latitude: 31.631583,
      longitude: -7.990912,
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.631583,-7.990912',
      practicalTips: [
        'Comptoir takeaway (quelques tabourets) — utile si Bacha est saturé.',
        'Ouvrez le pin « Simple Specialty Coffee », pas le musée Dar El Bacha.',
        'Sur Rue Dar El Bacha, à quelques minutes à pied de Bacha Coffee.',
      ],
    ),
    PlaceGuide(
      id: 'place-cafe-des-epices',
      name: 'Café des Épices',
      cityName: 'Marrakech',
      category: PlaceCategory.cafe,
      categoryLabel: 'Café',
      neighborhood: 'Médina',
      priceLevel: '€€',
      isEditorsPick: false,
      imageColor: Color(0xFFC45C26),
      summary:
          'Café coffee & cuisine sur la Place des Épices — '
          'terrasse / rooftop avec vue Atlas, pause médina accessible.',
      bestTimeToVisit: 'Matin ou fin d\'après-midi sur la terrasse',
      address: '75 Rahba Lakdima, Médina, Marrakech',
      latitude: 31.629062,
      longitude: -7.987323,
      phone: '+212524391770',
      website: 'https://cafedesepices.ma/',
      email: 'contact@cafedesepices.ma',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.629062,-7.987323',
      openingHours: PlaceOpeningHours(
        entries: [
          PlaceHoursEntry(dayLabel: 'Lundi', hoursLabel: '09:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Mardi', hoursLabel: '09:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Mercredi', hoursLabel: '09:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Jeudi', hoursLabel: '09:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Vendredi', hoursLabel: '09:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Samedi', hoursLabel: '09:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Dimanche', hoursLabel: '09:00–23:00'),
        ],
      ),
      practicalTips: [
        '75 Rahba Lakdima ; walk-in le jour, réservez le soir via le site '
            'ou au +212 524 39 17 70.',
        'Distinct du hammam Place des Épices et des restaurants Nomad / '
            'Le Jardin (même groupe).',
        'Repère : Place des Épices / Rahba Lakdima.',
      ],
    ),
    PlaceGuide(
      id: 'place-kartell-kollektiv',
      name: 'Kartell Kollektiv',
      cityName: 'Marrakech',
      category: PlaceCategory.cafe,
      categoryLabel: 'Café',
      neighborhood: 'Guéliz',
      priceLevel: '€€',
      isEditorsPick: false,
      imageColor: Color(0xFF2F4F4F),
      summary:
          'Coffee shop specialty à Guéliz — espresso soigné, ambiance calme '
          'et creative (pas une terrasse médina).',
      bestTimeToVisit: 'Matinée ou après-midi en semaine',
      address: '14 Rue Halab, Guéliz, Marrakech',
      latitude: 31.636385,
      longitude: -8.009579,
      website: 'https://kartell.space/',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.636385,-8.009579',
      practicalTips: [
        'Ouvrez le pin Guéliz, 14 Rue Halab uniquement — la marque a aussi '
            'un espace Médina (non listé ici).',
        'Orthographe : Kartell (pas « Kartel »).',
        'Idéal pour un coffee break dans la ville nouvelle.',
      ],
    ),
    PlaceGuide(
      id: 'place-cafe-clock',
      name: 'Café Clock',
      cityName: 'Marrakech',
      category: PlaceCategory.cafe,
      categoryLabel: 'Café',
      neighborhood: 'Kasbah',
      priceLevel: '€€',
      isEditorsPick: false,
      imageColor: Color(0xFF4A6741),
      summary:
          'Café culturel coffee & food en Kasbah — terrasses, musique et '
          'ateliers ; distinct des coffee shops Guéliz.',
      bestTimeToVisit: 'Déjeuner ou soirée culturelle',
      address: '224 Derb Chtouka, Kasbah, Marrakech',
      latitude: 31.613029,
      longitude: -7.987289,
      phone: '+212524378367',
      website: 'https://www.cafeclock.com/',
      mapsUrl:
          'https://www.google.com/maps/search/?api=1&query=31.613029,-7.987289',
      openingHours: PlaceOpeningHours(
        entries: [
          PlaceHoursEntry(dayLabel: 'Lundi', hoursLabel: '09:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Mardi', hoursLabel: '09:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Mercredi', hoursLabel: '09:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Jeudi', hoursLabel: '09:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Vendredi', hoursLabel: '09:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Samedi', hoursLabel: '09:00–23:00'),
          PlaceHoursEntry(dayLabel: 'Dimanche', hoursLabel: '09:00–23:00'),
        ],
      ),
      practicalTips: [
        '224 Derb Chtouka (Kasbah) — pas le Café Clock de Fès ou Chefchaouen.',
        'Proche des Tombeaux saadiens ; ne confondez pas avec '
            '« Les Jardins de la Medina ».',
        'Réservez ou renseignez-vous au +212 524 37 83 67.',
      ],
    ),
    PlaceGuide(
      id: 'place-hassan-ii',
      name: 'Mosquée Hassan II',
      cityName: 'Casablanca',
      category: PlaceCategory.monument,
      categoryLabel: 'Monument',
      neighborhood: 'Corniche',
      priceLevel: '€€',
      isEditorsPick: true,
      imageColor: Color(0xFF1B4965),
      summary:
          'Deuxième plus grande mosquée au monde — architecture spectaculaire '
          'dominant l\'Atlantique.',
      bestTimeToVisit: 'Visite guidée le matin',
      mapsUrl: 'https://maps.google.com/?q=Mosquée+Hassan+II+Casablanca',
      latitude: 33.6085,
      longitude: -7.6326,
      practicalTips: [
        'Les visites guidées sont obligatoires pour les non-musulmans.',
        'Retirez vos chaussures et habillez-vous modestement.',
        'La visite dure environ 1h — réservez à l\'avance en haute saison.',
      ],
    ),
    PlaceGuide(
      id: 'place-corniche',
      name: 'Corniche Ain Diab',
      cityName: 'Casablanca',
      category: PlaceCategory.plage,
      categoryLabel: 'Plage',
      neighborhood: 'Ain Diab',
      priceLevel: '€€',
      isEditorsPick: false,
      imageColor: Color(0xFF48CAE4),
      summary:
          'Promenade en bord de mer avec plages, cafés et restaurants — '
          'incontournable de Casablanca.',
      bestTimeToVisit: 'Fin d\'après-midi en semaine',
      mapsUrl: 'https://maps.google.com/?q=Corniche+Ain+Diab+Casablanca',
      latitude: 33.595,
      longitude: -7.677,
      practicalTips: [
        'Le stationnement est difficile le week-end — privilégiez un taxi.',
        'Les plages publiques sont gratuites, les clubs de plage sont payants.',
        'Idéal pour un coucher de soleil suivi d\'un dîner en bord de mer.',
      ],
    ),
    PlaceGuide(
      id: 'place-marche-central',
      name: 'Marché Central',
      cityName: 'Casablanca',
      category: PlaceCategory.restaurant,
      categoryLabel: 'Restaurant',
      neighborhood: 'Centre-ville',
      priceLevel: '€',
      isEditorsPick: true,
      imageColor: Color(0xFFE07A5F),
      summary:
          'Marché couvert historique transformé en food court — '
          'fruits de mer, cuisine marocaine et ambiance locale.',
      bestTimeToVisit: 'Déjeuner entre 12h et 14h',
      mapsUrl: 'https://maps.google.com/?q=Marché+Central+Casablanca',
      latitude: 33.594,
      longitude: -7.618,
      practicalTips: [
        'Les étals de poisson grillé sont les plus populaires.',
        'Arrivez tôt pour avoir une table aux heures de pointe.',
        'Les prix sont affichés — peu de négociation ici.',
      ],
    ),
    PlaceGuide(
      id: 'place-musee-judaisme',
      name: 'Musée du Judaïsme Marocain',
      cityName: 'Casablanca',
      category: PlaceCategory.musee,
      categoryLabel: 'Musée',
      neighborhood: 'Centre-ville',
      priceLevel: '€€',
      isEditorsPick: false,
      imageColor: Color(0xFF6B4226),
      summary:
          'Musée unique retraçant l\'histoire millénaire du judaïsme marocain '
          'dans un ancien temple.',
      bestTimeToVisit: 'Matinée en semaine',
      mapsUrl: 'https://maps.google.com/?q=Musée+du+Judaïsme+Casablanca',
      latitude: 33.601,
      longitude: -7.631,
      practicalTips: [
        'Fermé le samedi — vérifiez les horaires avant de vous déplacer.',
        'La visite guidée enrichit beaucoup l\'expérience.',
        'Comptez 1h pour une visite complète.',
      ],
    ),
    PlaceGuide(
      id: 'place-habous',
      name: 'Quartier Habous',
      cityName: 'Casablanca',
      category: PlaceCategory.souk,
      categoryLabel: 'Souk',
      neighborhood: 'Habous',
      priceLevel: '€',
      isEditorsPick: false,
      imageColor: Color(0xFFD4A373),
      summary:
          'Quartier néo-traditionnel avec souks, pâtisseries et artisanat — '
          'alternative plus calme à la Médina de Marrakech.',
      bestTimeToVisit: 'Matinée',
      mapsUrl: 'https://maps.google.com/?q=Quartier+Habous+Casablanca',
      latitude: 33.5735,
      longitude: -7.606,
      practicalTips: [
        'Les pâtisseries orientales du quartier sont réputées.',
        'Moins touristique que la Médina — les prix sont plus doux.',
        'Idéal pour acheter des souvenirs artisanaux.',
      ],
    ),
    PlaceGuide(
      id: 'place-tour-hassan',
      name: 'Tour Hassan',
      cityName: 'Rabat',
      category: PlaceCategory.monument,
      categoryLabel: 'Monument',
      neighborhood: 'Centre-ville',
      priceLevel: '€',
      isEditorsPick: true,
      imageColor: Color(0xFFB5835A),
      summary:
          'Minaret inachevé du XIIe siècle et esplanade monumentale — '
          'symbole emblématique de Rabat.',
      bestTimeToVisit: 'Fin d\'après-midi pour la lumière',
      mapsUrl: 'https://maps.google.com/?q=Tour+Hassan+Rabat',
      latitude: 34.0242,
      longitude: -6.8227,
      practicalTips: [
        'L\'esplanade est gratuite et ouverte en continu.',
        'Combinez avec la visite du Mausolée Mohammed V juste en face.',
        'Très photogénique au coucher du soleil.',
      ],
    ),
    PlaceGuide(
      id: 'place-oudayas',
      name: 'Kasbah des Oudayas',
      cityName: 'Rabat',
      category: PlaceCategory.monument,
      categoryLabel: 'Monument',
      neighborhood: 'Oudayas',
      priceLevel: '€',
      isEditorsPick: true,
      imageColor: Color(0xFF3D5A80),
      summary:
          'Citadelle aux ruelles bleues et blanches surplombant l\'embouchure '
          'du Bouregreg — le quartier le plus pittoresque de Rabat.',
      bestTimeToVisit: 'Matinée en semaine',
      mapsUrl: 'https://maps.google.com/?q=Kasbah+des+Oudayas+Rabat',
      latitude: 34.0319,
      longitude: -6.8369,
      practicalTips: [
        'Les ruelles sont étroites — chaussures confortables recommandées.',
        'Le café Maure offre une vue magnifique sur le fleuve.',
        'Moins de monde tôt le matin.',
      ],
    ),
    PlaceGuide(
      id: 'place-chellah',
      name: 'Chellah',
      cityName: 'Rabat',
      category: PlaceCategory.monument,
      categoryLabel: 'Monument',
      neighborhood: 'Chellah',
      priceLevel: '€€',
      isEditorsPick: false,
      imageColor: Color(0xFF588157),
      summary:
          'Site archéologique romain et médiéval aux jardins luxuriants — '
          'havre de paix en ville.',
      bestTimeToVisit: 'Matinée, surtout au printemps',
      mapsUrl: 'https://maps.google.com/?q=Chellah+Rabat',
      latitude: 34.0065,
      longitude: -6.8206,
      practicalTips: [
        'Les nids de storks sur les ruines sont spectaculaires au printemps.',
        'Prévoyez 1h30 pour explorer le site en entier.',
        'Ombragé et frais — idéal par temps chaud.',
      ],
    ),
    PlaceGuide(
      id: 'place-musee-rabat',
      name: 'Musée Mohammed VI',
      cityName: 'Rabat',
      category: PlaceCategory.musee,
      categoryLabel: 'Musée',
      neighborhood: 'Centre-ville',
      priceLevel: '€€',
      isEditorsPick: false,
      imageColor: Color(0xFF7B2D26),
      summary:
          'Musée d\'art moderne et contemporain africain — '
          'collection remarquable dans une architecture épurée.',
      bestTimeToVisit: 'Après-midi en semaine',
      mapsUrl: 'https://maps.google.com/?q=Musée+Mohammed+VI+Rabat',
      latitude: 34.0125,
      longitude: -6.844,
      practicalTips: [
        'Fermé le mardi — vérifiez les horaires.',
        'La collection permanente est accessible avec un seul billet.',
        'Comptez 1h30 pour une visite confortable.',
      ],
    ),
    PlaceGuide(
      id: 'place-plage-rabat',
      name: 'Plage de Rabat',
      cityName: 'Rabat',
      category: PlaceCategory.plage,
      categoryLabel: 'Plage',
      neighborhood: 'Plage des Oudayas',
      priceLevel: '€',
      isEditorsPick: false,
      imageColor: Color(0xFF90E0EF),
      summary:
          'Plage urbaine accessible depuis la Kasbah — '
          'idéale pour une pause fraîcheur en été.',
      bestTimeToVisit: 'Fin d\'après-midi',
      mapsUrl: 'https://maps.google.com/?q=Plage+Rabat',
      latitude: 34.028,
      longitude: -6.845,
      practicalTips: [
        'La plage est surveillée en été.',
        'Accessible à pied depuis la Kasbah des Oudayas.',
        'Évitez les week-ends d\'été si vous cherchez le calme.',
      ],
    ),
  ];
}
