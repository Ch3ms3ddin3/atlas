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
enum PriceObservationScope {
  citySpecific,
  national,
}

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
  String get sourceLabel =>
      '${sourceType.storageLabel} · $sourceName';

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

/// Catalogue Wave 1 — observations vérifiées uniquement (sources opérateurs).
///
/// Montants copiés depuis les pages officielles au [retrievedAt] indiqué.
/// Ne pas importer [PriceCatalog].
abstract final class PriceObservationCatalog {
  /// Date de vérification éditoriale de cette vague (re-vérif. Orange 2026-08-11).
  static final retrievedAt = DateTime.utc(2026, 8, 11);

  static const wave1Cities = <String>[
    'Marrakech',
    'Casablanca',
    'Rabat',
  ];

  static List<PriceObservationCatalogEntry> get entries =>
      List<PriceObservationCatalogEntry>.unmodifiable([
        ..._casablancaTram,
        ..._rabatTram,
        ..._nationalOrangeMobile,
        ..._nationalOrangeInternet,
        // inwi SIM prépayée retirée : brochure PDF officielle 404 (2026-08-11).
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
      sourceUrl:
          'https://www.casatramway.ma/conditions-generales-de-vente-cgv',
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
      sourceUrl:
          'https://www.casatramway.ma/conditions-generales-de-vente-cgv',
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
      sourceUrl:
          'https://www.casatramway.ma/conditions-generales-de-vente-cgv',
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
      sourceUrl:
          'https://www.casatramway.ma/conditions-generales-de-vente-cgv',
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
      sourceUrl:
          'https://www.casatramway.ma/conditions-generales-de-vente-cgv',
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
