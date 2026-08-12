import '../domain/models/price_models.dart';
import '../domain/models/price_observation.dart';

/// Provenance d'une observation — stocké hors schéma SQL via le libellé [source].
enum PriceObservationSourceType {
  officialOperator,
  officialCommercialOffer,
  regulatedPublicTariff,
}

extension PriceObservationSourceTypeLabels on PriceObservationSourceType {
  String get storageLabel => switch (this) {
    PriceObservationSourceType.officialOperator => 'official_operator',
    PriceObservationSourceType.officialCommercialOffer =>
      'official_commercial_offer',
    PriceObservationSourceType.regulatedPublicTariff =>
      'regulated_public_tariff',
  };
}

/// Portée géographique éditoriale.
///
/// Les tarifs nationaux sont stockés **une seule fois** avec
/// [PriceNationalCity.name] ; le filtre Prix les inclut pour chaque ville.
enum PriceObservationScope { citySpecific, national }

/// Entrée catalogue locale (préparation P1) — jamais d'estimation.
class PriceObservationCatalogEntry {
  const PriceObservationCatalogEntry({
    required this.slug,
    required this.itemName,
    required this.category,
    required this.cityName,
    required this.scope,
    required this.unitLabel,
    required this.currentAmountMad,
    required this.sourceName,
    required this.sourceUrl,
    required this.sourceType,
    required this.retrievedAt,
    required this.confidence,
    this.district,
    this.minAmountMad,
    this.avgAmountMad,
    this.maxAmountMad,
    this.currency = 'MAD',
    this.verificationStatus = PriceVerificationStatus.verified,
    this.isPublished = true,
    this.atlasScore,
    this.notes,
  });

  final String slug;
  final String itemName;
  final PriceIntelligenceCategory category;
  final String cityName;
  final PriceObservationScope scope;
  final String? district;
  final String unitLabel;
  final double currentAmountMad;
  final double? minAmountMad;
  final double? avgAmountMad;
  final double? maxAmountMad;
  final String currency;
  final String sourceName;
  final String sourceUrl;
  final PriceObservationSourceType sourceType;
  final DateTime retrievedAt;
  final PriceConfidence confidence;
  final PriceVerificationStatus verificationStatus;
  final bool isPublished;
  final int? atlasScore;
  final String? notes;

  /// Libellé `source` compatible schéma (type + nom).
  String get sourceLabel => '${sourceType.storageLabel} · $sourceName';

  PriceObservation toObservation() {
    return PriceObservation(
      id: slug,
      itemName: itemName,
      category: category,
      cityName: cityName,
      district: district,
      unitLabel: unitLabel,
      currentAmountMad: currentAmountMad,
      minAmountMad: minAmountMad,
      avgAmountMad: avgAmountMad,
      maxAmountMad: maxAmountMad,
      currency: currency,
      lastUpdatedAt: retrievedAt,
      source: sourceLabel,
      sourceUrl: sourceUrl,
      confidence: confidence,
      verificationStatus: verificationStatus,
      atlasScore: atlasScore,
    );
  }
}

/// Catalogue Price Intelligence — observations vérifiées uniquement.
///
/// Wave 1 : transports Casa/Rabat + Orange national.
/// Wave 2 : culture Marrakech (billets officiels) + Majorelle/YSL (billetterie
/// officielle capturée 2026-08-12).
///
/// Montants copiés depuis les sources primaires au [retrievedAt] / [wave2RetrievedAt].
/// Ne pas importer le legacy [PriceCatalog] (estimations — hors Intelligence).
abstract final class PriceObservationCatalog {
  /// Date de vérification éditoriale Wave 1 (re-vérif. Orange 2026-08-11).
  static final retrievedAt = DateTime.utc(2026, 8, 11);

  /// Date de capture éditoriale Wave 2 (culture Marrakech + Majorelle/YSL).
  static final wave2RetrievedAt = DateTime.utc(2026, 8, 12);

  static const wave1Cities = <String>['Marrakech', 'Casablanca', 'Rabat'];

  static List<PriceObservationCatalogEntry> get entries =>
      List<PriceObservationCatalogEntry>.unmodifiable([
        ..._casablancaTram,
        ..._rabatTram,
        ..._nationalOrangeMobile,
        ..._nationalOrangeInternet,
        // inwi SIM prépayée retirée : brochure PDF officielle 404 (2026-08-11).
        ..._marrakechCultureWave2,
      ]);

  static List<PriceObservation> get asObservations =>
      entries.map((e) => e.toObservation()).toList(growable: false);

  // —— Casablanca · Casa Tramway (RATP Dev Casablanca) ——

  static final _casablancaTram = <PriceObservationCatalogEntry>[
    PriceObservationCatalogEntry(
      slug: 'publicTransport-tram-ticket-unitaire-casablanca',
      itemName: 'Ticket tram/busway — 1 voyage',
      category: PriceIntelligenceCategory.publicTransport,
      cityName: 'Casablanca',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par voyage',
      currentAmountMad: 8,
      sourceName: 'Casa Tramway — Ticket unitaire',
      sourceUrl:
          'https://www.casatramway.ma/titres/tickets/titre-de-voyage/ticket-unitaire',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: retrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 95,
      notes: '6 DH voyage + 2 DH support ticket selon page opérateur.',
    ),
    PriceObservationCatalogEntry(
      slug: 'publicTransport-tram-ticket-2voyages-casablanca',
      itemName: 'Ticket tram/busway — 2 voyages',
      category: PriceIntelligenceCategory.publicTransport,
      cityName: 'Casablanca',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'pour 2 voyages',
      currentAmountMad: 14,
      sourceName: 'Casa Tramway — Ticket unitaire',
      sourceUrl:
          'https://www.casatramway.ma/titres/tickets/titre-de-voyage/ticket-unitaire',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: retrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 90,
    ),
    PriceObservationCatalogEntry(
      slug: 'publicTransport-tram-voyage-carte-casablanca',
      itemName: 'Voyage sur carte rechargeable tram/busway',
      category: PriceIntelligenceCategory.publicTransport,
      cityName: 'Casablanca',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par voyage (hors support)',
      currentAmountMad: 6,
      sourceName: 'Casa Tramway — CGV (prix des titres)',
      sourceUrl: 'https://www.casatramway.ma/conditions-generales-de-vente-cgv',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: retrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 92,
      notes: 'CGV publiées le 26 novembre 2025.',
    ),
    PriceObservationCatalogEntry(
      slug: 'publicTransport-tram-carte-support-casablanca',
      itemName: 'Support carte rechargeable / abonnement tram',
      category: PriceIntelligenceCategory.publicTransport,
      cityName: 'Casablanca',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par carte (valable 5 ans)',
      currentAmountMad: 15,
      sourceName: 'Casa Tramway — CGV (prix des titres)',
      sourceUrl: 'https://www.casatramway.ma/conditions-generales-de-vente-cgv',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: retrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 70,
    ),
    PriceObservationCatalogEntry(
      slug: 'publicTransport-tram-abo-hebdo-casablanca',
      itemName: 'Abonnement hebdomadaire tram/busway',
      category: PriceIntelligenceCategory.publicTransport,
      cityName: 'Casablanca',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par semaine (hors support)',
      currentAmountMad: 60,
      sourceName: 'Casa Tramway — CGV (prix des titres)',
      sourceUrl: 'https://www.casatramway.ma/conditions-generales-de-vente-cgv',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: retrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 80,
    ),
    PriceObservationCatalogEntry(
      slug: 'publicTransport-tram-abo-mensuel-casablanca',
      itemName: 'Abonnement mensuel tram/busway',
      category: PriceIntelligenceCategory.publicTransport,
      cityName: 'Casablanca',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par mois (hors support)',
      currentAmountMad: 230,
      sourceName: 'Casa Tramway — CGV (prix des titres)',
      sourceUrl: 'https://www.casatramway.ma/conditions-generales-de-vente-cgv',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: retrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 85,
    ),
    PriceObservationCatalogEntry(
      slug: 'publicTransport-tram-abo-etudiant-casablanca',
      itemName: 'Abonnement mensuel étudiant tram/busway',
      category: PriceIntelligenceCategory.publicTransport,
      cityName: 'Casablanca',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par mois (hors support, ≤25 ans)',
      currentAmountMad: 150,
      sourceName: 'Casa Tramway — CGV (prix des titres)',
      sourceUrl: 'https://www.casatramway.ma/conditions-generales-de-vente-cgv',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: retrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 75,
    ),
  ];

  // —— Rabat · Tramway Rabat-Salé ——

  static final _rabatTram = <PriceObservationCatalogEntry>[
    PriceObservationCatalogEntry(
      slug: 'publicTransport-tram-ticket-unitaire-rabat',
      itemName: 'Ticket unitaire tramway Rabat-Salé',
      category: PriceIntelligenceCategory.publicTransport,
      cityName: 'Rabat',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par voyage (1 h, correspondance)',
      currentAmountMad: 7,
      sourceName: 'Tramway Rabat-Salé — Ticket et infractions',
      sourceUrl: 'https://www.tram-way.ma/fr/ticket-et-infractions/',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: retrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 95,
    ),
    PriceObservationCatalogEntry(
      slug: 'publicTransport-tram-ticket-parking-pr-rabat',
      itemName: 'Ticket parking-relais (P+R) tramway',
      category: PriceIntelligenceCategory.parking,
      cityName: 'Rabat',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'aller-retour + parking-relais',
      currentAmountMad: 14,
      sourceName: 'Tramway Rabat-Salé — Ticket et infractions',
      sourceUrl: 'https://www.tram-way.ma/fr/ticket-et-infractions/',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: retrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 78,
    ),
    PriceObservationCatalogEntry(
      slug: 'publicTransport-tram-ticket-trambus-rabat',
      itemName: 'Ticket Trambus (tram + bus ligne 30)',
      category: PriceIntelligenceCategory.publicTransport,
      cityName: 'Rabat',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par titre intermodal',
      currentAmountMad: 10,
      sourceName: 'Tramway Rabat-Salé — Ticket et infractions',
      sourceUrl: 'https://www.tram-way.ma/fr/ticket-et-infractions/',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: retrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 82,
    ),
    PriceObservationCatalogEntry(
      slug: 'publicTransport-tram-abo-mensuel-rabat',
      itemName: 'Abonnement mensuel tramway (tout public)',
      category: PriceIntelligenceCategory.publicTransport,
      cityName: 'Rabat',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par mois',
      currentAmountMad: 270,
      sourceName: 'Tramway Rabat-Salé — Abonnement',
      sourceUrl: 'https://www.tram-way.ma/fr/abonnement/',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: retrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 85,
    ),
    PriceObservationCatalogEntry(
      slug: 'publicTransport-tram-abo-etudiant-rabat',
      itemName: 'Abonnement mensuel tramway étudiant',
      category: PriceIntelligenceCategory.publicTransport,
      cityName: 'Rabat',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par mois (<26 ans)',
      currentAmountMad: 160,
      sourceName: 'Tramway Rabat-Salé — Abonnement',
      sourceUrl: 'https://www.tram-way.ma/fr/abonnement/',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: retrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 75,
    ),
    PriceObservationCatalogEntry(
      slug: 'publicTransport-tram-abo-trimestriel-rabat',
      itemName: 'Abonnement trimestriel tramway (tout public)',
      category: PriceIntelligenceCategory.publicTransport,
      cityName: 'Rabat',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par trimestre',
      currentAmountMad: 750,
      sourceName: 'Tramway Rabat-Salé — Abonnement',
      sourceUrl: 'https://www.tram-way.ma/fr/abonnement/',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: retrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 72,
    ),
    PriceObservationCatalogEntry(
      slug: 'publicTransport-tram-abo-annuel-rabat',
      itemName: 'Abonnement annuel tramway (tout public)',
      category: PriceIntelligenceCategory.publicTransport,
      cityName: 'Rabat',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par an',
      currentAmountMad: 2700,
      sourceName: 'Tramway Rabat-Salé — Abonnement',
      sourceUrl: 'https://www.tram-way.ma/fr/abonnement/',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: retrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 68,
    ),
  ];

  // —— Marrakech · Culture & monuments (Wave 2) ——
  // Sources primaires capturées 2026-08-12. Pas de taxi / bus / parking.

  static final _marrakechCultureWave2 = <PriceObservationCatalogEntry>[
    PriceObservationCatalogEntry(
      slug: 'culture-palais-bahia-adulte-etranger-marrakech',
      itemName: 'Palais Bahia — entrée adulte étranger',
      category: PriceIntelligenceCategory.culture,
      cityName: 'Marrakech',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par personne',
      currentAmountMad: 100,
      sourceName: 'Ministère de la Culture — e-services Palais Bahia',
      sourceUrl: 'https://e-services.minculture.gov.ma/fr/tickets/palais-bahia',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: wave2RetrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 96,
      notes:
          'Autres tarifs publiés sur la même page : adulte Marocain/résident '
          '30 MAD ; enfant Marocain 7–13 ans 10 MAD ; enfant étranger 7–13 ans '
          '50 MAD. Gratuités Marocains le vendredi et certains jours de fêtes.',
    ),
    PriceObservationCatalogEntry(
      slug: 'culture-palais-bahia-adulte-marocain-resident-marrakech',
      itemName: 'Palais Bahia — entrée adulte Marocain / résident',
      category: PriceIntelligenceCategory.culture,
      cityName: 'Marrakech',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par personne',
      currentAmountMad: 30,
      sourceName: 'Ministère de la Culture — e-services Palais Bahia',
      sourceUrl: 'https://e-services.minculture.gov.ma/fr/tickets/palais-bahia',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: wave2RetrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 94,
    ),
    PriceObservationCatalogEntry(
      slug: 'culture-palais-el-badi-adulte-etranger-marrakech',
      itemName: 'Palais El Badi — entrée adulte étranger',
      category: PriceIntelligenceCategory.culture,
      cityName: 'Marrakech',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par personne',
      currentAmountMad: 100,
      sourceName: 'Ministère de la Culture — e-services Palais Badii',
      sourceUrl: 'https://e-services.minculture.gov.ma/fr/tickets/palais-badii',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: wave2RetrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 95,
      notes:
          'Autres tarifs publiés sur la même page : adulte Marocain/résident '
          '30 MAD ; enfant Marocain 7–13 ans 10 MAD ; enfant étranger 7–13 ans '
          '50 MAD.',
    ),
    PriceObservationCatalogEntry(
      slug: 'culture-palais-el-badi-adulte-marocain-resident-marrakech',
      itemName: 'Palais El Badi — entrée adulte Marocain / résident',
      category: PriceIntelligenceCategory.culture,
      cityName: 'Marrakech',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par personne',
      currentAmountMad: 30,
      sourceName: 'Ministère de la Culture — e-services Palais Badii',
      sourceUrl: 'https://e-services.minculture.gov.ma/fr/tickets/palais-badii',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: wave2RetrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 93,
    ),
    PriceObservationCatalogEntry(
      slug: 'culture-tombeaux-saadiens-adulte-etranger-marrakech',
      itemName: 'Tombeaux Saadiens — entrée adulte étranger',
      category: PriceIntelligenceCategory.culture,
      cityName: 'Marrakech',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par personne',
      currentAmountMad: 100,
      sourceName: 'Ministère de la Culture — e-services Tombeaux Saadiens',
      sourceUrl:
          'https://e-services.minculture.gov.ma/fr/tickets/tombeaux-saadiens',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: wave2RetrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 95,
      notes:
          'Autres tarifs publiés sur la même page : adulte Marocain/résident '
          '30 MAD ; enfant Marocain 7–13 ans 10 MAD ; enfant étranger 7–13 ans '
          '50 MAD.',
    ),
    PriceObservationCatalogEntry(
      slug: 'culture-tombeaux-saadiens-adulte-marocain-resident-marrakech',
      itemName: 'Tombeaux Saadiens — entrée adulte Marocain / résident',
      category: PriceIntelligenceCategory.culture,
      cityName: 'Marrakech',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par personne',
      currentAmountMad: 30,
      sourceName: 'Ministère de la Culture — e-services Tombeaux Saadiens',
      sourceUrl:
          'https://e-services.minculture.gov.ma/fr/tickets/tombeaux-saadiens',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: wave2RetrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 93,
    ),
    PriceObservationCatalogEntry(
      slug: 'culture-medersa-ben-youssef-adulte-marrakech',
      itemName: 'Médersa Ben Youssef — entrée adulte',
      category: PriceIntelligenceCategory.culture,
      cityName: 'Marrakech',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par personne',
      currentAmountMad: 50,
      sourceName: 'Médersa Ben Youssef — site officiel (Tarifs)',
      sourceUrl: 'https://www.medersabenyoussef.ma/',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: wave2RetrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 94,
      notes:
          'Site officiel : enfant de moins de 12 ans 10 MAD ; groupe de plus '
          'de 20 personnes 30 MAD. Billetterie en ligne en maintenance — '
          'achat sur place.',
    ),
    PriceObservationCatalogEntry(
      slug: 'culture-dar-el-bacha-adulte-etranger-marrakech',
      itemName: 'Dar El Bacha — entrée étranger',
      category: PriceIntelligenceCategory.culture,
      cityName: 'Marrakech',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par personne',
      currentAmountMad: 60,
      sourceName: 'Fondation Nationale des Musées — Dar El Bacha',
      sourceUrl: 'https://fnm.ma/museums/26',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: wave2RetrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 94,
    ),
    PriceObservationCatalogEntry(
      slug: 'culture-dar-el-bacha-adulte-marocain-resident-marrakech',
      itemName: 'Dar El Bacha — entrée Marocain / résident',
      category: PriceIntelligenceCategory.culture,
      cityName: 'Marrakech',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par personne',
      currentAmountMad: 25,
      sourceName: 'Fondation Nationale des Musées — Dar El Bacha',
      sourceUrl: 'https://fnm.ma/museums/26',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: wave2RetrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 92,
      notes:
          'FNM : moins de 18 ans Marocains/résidents 15 MAD '
          '(même page Tarifs et billets).',
    ),
    PriceObservationCatalogEntry(
      slug: 'culture-maison-photographie-adulte-marrakech',
      itemName: 'Maison de la Photographie — entrée adulte',
      category: PriceIntelligenceCategory.culture,
      cityName: 'Marrakech',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par personne',
      currentAmountMad: 80,
      sourceName: 'Maison de la Photographie — Horaires et tarifs',
      sourceUrl: 'https://maisondelaphotographie.ma/about/',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: wave2RetrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 93,
      notes:
          'Billet aussi valable au Musée de la Musique de Marrakech. '
          'Moins de 15 ans : gratuit. Paiement sur place uniquement.',
    ),
    PriceObservationCatalogEntry(
      slug: 'culture-maison-photographie-resident-marrakech',
      itemName: 'Maison de la Photographie — entrée résident',
      category: PriceIntelligenceCategory.culture,
      cityName: 'Marrakech',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par personne',
      currentAmountMad: 50,
      sourceName: 'Maison de la Photographie — Horaires et tarifs',
      sourceUrl: 'https://maisondelaphotographie.ma/about/',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: wave2RetrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 91,
    ),
    PriceObservationCatalogEntry(
      slug: 'culture-macaal-adulte-marrakech',
      itemName: 'MACAAL — entrée adulte',
      category: PriceIntelligenceCategory.culture,
      cityName: 'Marrakech',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par personne',
      currentAmountMad: 120,
      sourceName: 'MACAAL — Informations pratiques',
      sourceUrl: 'https://macaal.org/informations-pratiques',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: wave2RetrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 95,
      notes:
          'Inclut expositions + Parc de Sculptures d\'Al Maaden. '
          'Enfants (−12 ans) et étudiants : gratuit avec justificatif. '
          'Groupes (+10) : 110 MAD / personne.',
    ),
    PriceObservationCatalogEntry(
      slug: 'culture-macaal-resident-africain-marrakech',
      itemName: 'MACAAL — entrée résident / nationalité africaine',
      category: PriceIntelligenceCategory.culture,
      cityName: 'Marrakech',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par personne',
      currentAmountMad: 60,
      sourceName: 'MACAAL — Informations pratiques',
      sourceUrl: 'https://macaal.org/informations-pratiques',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: wave2RetrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 93,
      notes: 'Justificatif exigé (page officielle MACAAL).',
    ),
    PriceObservationCatalogEntry(
      slug: 'culture-jardin-majorelle-admission-marrakech',
      itemName: 'Jardin Majorelle — droit d\'entrée',
      category: PriceIntelligenceCategory.culture,
      cityName: 'Marrakech',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par personne',
      currentAmountMad: 170,
      sourceName: 'Billetterie officielle Jardin Majorelle',
      sourceUrl: 'https://tickets.jardinmajorelle.com/visite',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: wave2RetrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 97,
      notes:
          'Tarif « Admission Fee » affiché sur la billetterie officielle '
          '(capture 2026-08-12). Étudiants internationaux / enfants dès '
          '10 ans : 95 MAD. Réservation QR uniquement sur ce site.',
    ),
    PriceObservationCatalogEntry(
      slug: 'culture-jardin-majorelle-marocain-resident-marrakech',
      itemName: 'Jardin Majorelle — citoyens marocains / résidents étrangers',
      category: PriceIntelligenceCategory.culture,
      cityName: 'Marrakech',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par personne',
      currentAmountMad: 75,
      sourceName: 'Billetterie officielle Jardin Majorelle',
      sourceUrl: 'https://tickets.jardinmajorelle.com/visite',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: wave2RetrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 95,
      notes:
          'Libellé billetterie : « Moroccan citizens and foreign residents '
          'in Morocco » (capture 2026-08-12, nationalité Morocco).',
    ),
    PriceObservationCatalogEntry(
      slug: 'culture-musee-ysl-admission-marrakech',
      itemName: 'Musée Yves Saint Laurent — droit d\'entrée',
      category: PriceIntelligenceCategory.culture,
      cityName: 'Marrakech',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par personne',
      currentAmountMad: 140,
      sourceName: 'Billetterie officielle Jardin Majorelle (Musée YSL)',
      sourceUrl: 'https://tickets.jardinmajorelle.com/visite',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: wave2RetrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 96,
      notes:
          'Tarif « Admission Fee » pour l\'option Musée YSL '
          '(capture 2026-08-12). Étudiants internationaux / enfants dès '
          '10 ans : 75 MAD. Fermé le mercredi.',
    ),
    PriceObservationCatalogEntry(
      slug: 'culture-musee-ysl-marocain-resident-marrakech',
      itemName:
          'Musée Yves Saint Laurent — citoyens marocains / résidents étrangers',
      category: PriceIntelligenceCategory.culture,
      cityName: 'Marrakech',
      scope: PriceObservationScope.citySpecific,
      unitLabel: 'par personne',
      currentAmountMad: 55,
      sourceName: 'Billetterie officielle Jardin Majorelle (Musée YSL)',
      sourceUrl: 'https://tickets.jardinmajorelle.com/visite',
      sourceType: PriceObservationSourceType.officialOperator,
      retrievedAt: wave2RetrievedAt,
      confidence: PriceConfidence.high,
      atlasScore: 94,
      notes:
          'Libellé billetterie : « Moroccan citizens and foreign residents '
          'in Morocco » pour l\'option Musée YSL (capture 2026-08-12).',
    ),
  ];

  // —— National · Orange Maroc (stocké une fois) ——

  static List<PriceObservationCatalogEntry> get _nationalOrangeMobile {
    const offers = <_NationalOffer>[
      _NationalOffer(
        itemKey: 'sim-prepaid-20',
        itemName: 'Carte SIM prépayée Orange (20 DH de crédit inclus)',
        category: PriceIntelligenceCategory.mobilePlans,
        unitLabel: 'par carte SIM / eSIM',
        amount: 20,
        sourceName: 'Orange Maroc boutique — Offres prépayées',
        sourceUrl: 'https://boutique.orange.ma/en/prepaid-mobile-plans',
        atlasScore: 88,
      ),
      _NationalOffer(
        itemKey: 'marhaba-7j-120',
        itemName: 'Offre Orange Marhaba 7 jours',
        category: PriceIntelligenceCategory.mobilePlans,
        unitLabel: 'par offre (7 jours)',
        amount: 120,
        sourceName: 'Orange Maroc boutique — Offres prépayées',
        sourceUrl: 'https://boutique.orange.ma/en/prepaid-mobile-plans',
        atlasScore: 93,
      ),
      _NationalOffer(
        itemKey: 'marhaba-14j-220',
        itemName: 'Offre Orange Marhaba 14 jours',
        category: PriceIntelligenceCategory.mobilePlans,
        unitLabel: 'par offre (14 jours)',
        amount: 220,
        sourceName: 'Orange Maroc boutique — Offres prépayées',
        sourceUrl: 'https://boutique.orange.ma/en/prepaid-mobile-plans',
        atlasScore: 90,
      ),
      _NationalOffer(
        itemKey: 'marhaba-30j-320',
        itemName: 'Offre Orange Marhaba 30 jours',
        category: PriceIntelligenceCategory.mobilePlans,
        unitLabel: 'par offre (30 jours)',
        amount: 320,
        sourceName: 'Orange Maroc boutique — Offres prépayées',
        sourceUrl: 'https://boutique.orange.ma/en/prepaid-mobile-plans',
        atlasScore: 87,
      ),
      _NationalOffer(
        itemKey: 'forfait-yo-max-199',
        itemName: 'Forfait Orange Yo Max 52 Go + 10 h',
        category: PriceIntelligenceCategory.mobilePlans,
        unitLabel: 'par mois',
        amount: 199,
        sourceName: 'Orange Maroc boutique — Forfait Yo Max 199 DH',
        sourceUrl:
            'https://boutique.orange.ma/en/produit/forfait-yo-max-52go-10h-d-appels-199dh',
        atlasScore: 84,
      ),
    ];
    return _nationalOnce(offers);
  }

  static List<PriceObservationCatalogEntry> get _nationalOrangeInternet {
    const offers = <_NationalOffer>[
      _NationalOffer(
        itemKey: 'dar-box-4g-199',
        itemName: 'Orange Dar Box 4G+ 199',
        category: PriceIntelligenceCategory.internet,
        unitLabel: 'par mois (hors frais d’activation / box)',
        amount: 199,
        sourceName: 'Orange Maroc boutique — Dar Box 4G+',
        sourceUrl: 'https://boutique.orange.ma/en/offres-dar-box/dar-box',
        atlasScore: 86,
      ),
      _NationalOffer(
        itemKey: 'dar-box-4g-249',
        itemName: 'Orange Dar Box 4G+ 249',
        category: PriceIntelligenceCategory.internet,
        unitLabel: 'par mois (hors frais d’activation / box)',
        amount: 249,
        sourceName: 'Orange Maroc boutique — Dar Box 4G+',
        sourceUrl: 'https://boutique.orange.ma/en/offres-dar-box/dar-box',
        atlasScore: 80,
      ),
      _NationalOffer(
        itemKey: 'dar-box-5g-299',
        itemName: 'Orange Dar Box 5G 299',
        category: PriceIntelligenceCategory.internet,
        unitLabel: 'par mois (hors frais d’activation / box)',
        amount: 299,
        sourceName: 'Orange Maroc boutique — Dar Box 5G',
        sourceUrl: 'https://boutique.orange.ma/en/offres-dar-box/dar-box-5g',
        atlasScore: 82,
      ),
    ];
    return _nationalOnce(offers);
  }

  /// Une ligne par offre nationale — [PriceNationalCity.name], sans réplication ville.
  static List<PriceObservationCatalogEntry> _nationalOnce(
    List<_NationalOffer> offers, {
    String slugPrefix = 'mobilePlans-orange',
  }) {
    return [
      for (final offer in offers)
        PriceObservationCatalogEntry(
          slug: _nationalSlug(offer, slugPrefix: slugPrefix),
          itemName: offer.itemName,
          category: offer.category,
          cityName: PriceNationalCity.name,
          scope: PriceObservationScope.national,
          unitLabel: offer.unitLabel,
          currentAmountMad: offer.amount,
          sourceName: offer.sourceName,
          sourceUrl: offer.sourceUrl,
          sourceType: PriceObservationSourceType.officialCommercialOffer,
          retrievedAt: retrievedAt,
          confidence: PriceConfidence.high,
          atlasScore: offer.atlasScore,
          notes:
              'Tarif national opérateur — stocké une fois (city_name = National).',
        ),
    ];
  }

  static String _nationalSlug(
    _NationalOffer offer, {
    required String slugPrefix,
  }) {
    final prefix = offer.category == PriceIntelligenceCategory.internet
        ? 'internet-orange'
        : slugPrefix;
    return '$prefix-${offer.itemKey}';
  }

  /// Anciens slugs répliqués par ville (pré-correctif national-once).
  /// Utilisés pour DELETE de nettoyage dans la migration additive.
  static List<String> get retiredNationalReplicaSlugs {
    const orangeMobileKeys = <String>[
      'sim-prepaid-20',
      'marhaba-7j-120',
      'marhaba-14j-220',
      'marhaba-30j-320',
      'forfait-yo-max-199',
    ];
    const orangeInternetKeys = <String>[
      'dar-box-4g-199',
      'dar-box-4g-249',
      'dar-box-5g-299',
    ];
    const inwiKeys = <String>['sim-prepaid-20'];
    const citySuffixes = <String>['marrakech', 'casablanca', 'rabat'];

    return [
      for (final city in citySuffixes) ...[
        for (final key in orangeMobileKeys) 'mobilePlans-orange-$key-$city',
        for (final key in orangeInternetKeys) 'internet-orange-$key-$city',
        for (final key in inwiKeys) 'mobilePlans-inwi-$key-$city',
      ],
    ];
  }
}

class _NationalOffer {
  const _NationalOffer({
    required this.itemKey,
    required this.itemName,
    required this.category,
    required this.unitLabel,
    required this.amount,
    required this.sourceName,
    required this.sourceUrl,
    required this.atlasScore,
  });

  final String itemKey;
  final String itemName;
  final PriceIntelligenceCategory category;
  final String unitLabel;
  final double amount;
  final String sourceName;
  final String sourceUrl;
  final int atlasScore;
}
