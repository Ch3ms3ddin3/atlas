import 'package:atlas/features/prices/data/price_observation_catalog.dart';
import 'package:atlas/features/prices/data/price_observation_catalog_validator.dart';
import 'package:atlas/features/prices/data/price_observation_query.dart';
import 'package:atlas/features/prices/data/resilient_price_intelligence_repository.dart';
import 'package:atlas/features/prices/domain/models/price_models.dart';
import 'package:atlas/features/prices/domain/models/price_observation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalogue Wave 1 valide métadonnées sources et contraintes', () {
    final errors = PriceObservationCatalogValidator.validate();
    expect(errors, isEmpty, reason: errors.join('\n'));
    expect(PriceObservationCatalog.entries.length, 22);
  });

  test('pas de slugs dupliqués et MAD strict', () {
    final slugs = PriceObservationCatalog.entries.map((e) => e.slug).toList();
    expect(slugs.toSet().length, slugs.length);
    for (final entry in PriceObservationCatalog.entries) {
      expect(entry.currency, 'MAD');
      expect(entry.currentAmountMad, greaterThan(0));
      expect(entry.sourceUrl, startsWith('http'));
      expect(entry.verificationStatus, PriceVerificationStatus.verified);
      expect(entry.isPublished, isTrue);
    }
  });

  test('chaque produit national est stocké une seule fois', () {
    final nationals = PriceObservationCatalog.entries
        .where((e) => e.scope == PriceObservationScope.national)
        .toList();
    expect(nationals.length, 8);
    for (final entry in nationals) {
      expect(entry.cityName, PriceNationalCity.name);
      expect(entry.slug.contains('marrakech'), isFalse);
      expect(entry.slug.contains('casablanca'), isFalse);
      expect(entry.slug.contains('rabat'), isFalse);
      expect(entry.slug.contains('inwi'), isFalse);
    }
    final productKeys = nationals
        .map((e) => '${e.category.name}|${e.itemName}')
        .toList();
    expect(productKeys.toSet().length, productKeys.length);
  });

  test('répartition scopes city-specific vs national', () {
    var national = 0;
    var citySpecific = 0;
    for (final entry in PriceObservationCatalog.entries) {
      switch (entry.scope) {
        case PriceObservationScope.national:
          national += 1;
        case PriceObservationScope.citySpecific:
          citySpecific += 1;
      }
    }
    expect(national, 8);
    expect(citySpecific, 14);
    expect(
      PriceObservationCatalog.entries
          .where((e) => e.cityName == 'Casablanca')
          .length,
      7,
    );
    expect(
      PriceObservationCatalog.entries.where((e) => e.cityName == 'Rabat').length,
      7,
    );
    expect(
      PriceObservationCatalog.entries
          .where((e) => e.cityName == 'Marrakech')
          .length,
      0,
    );
  });

  test('confiance high uniquement dans Wave 1 actuel', () {
    for (final entry in PriceObservationCatalog.entries) {
      expect(entry.confidence, PriceConfidence.high);
    }
  });

  test('nationaux visibles pour Marrakech, Casablanca et Rabat', () {
    final source = PriceObservationCatalog.asObservations;
    final nationalNames = PriceObservationCatalog.entries
        .where((e) => e.scope == PriceObservationScope.national)
        .map((e) => e.itemName)
        .toSet();

    for (final city in PriceObservationCatalog.wave1Cities) {
      final items = PriceObservationQuery.filter(
        PriceIntelligenceQuery(cityName: city),
        source: source,
      );
      expect(items, isNotEmpty, reason: city);
      final returnedNationals =
          items.where((e) => e.isNational).map((e) => e.itemName).toSet();
      expect(
        returnedNationals,
        nationalNames,
        reason: 'nationaux manquants pour $city',
      );
    }
  });

  test('observations city-specific ne fuient pas vers une autre ville', () {
    final source = PriceObservationCatalog.asObservations;

    final marrakech = PriceObservationQuery.filter(
      const PriceIntelligenceQuery(cityName: 'Marrakech'),
      source: source,
    );
    expect(
      marrakech.any((e) => e.cityName == 'Casablanca' || e.cityName == 'Rabat'),
      isFalse,
    );
    expect(
      marrakech.any((e) => e.itemName.contains('tram') || e.itemName.contains('Tram')),
      isFalse,
    );

    final casablanca = PriceObservationQuery.filter(
      const PriceIntelligenceQuery(cityName: 'Casablanca'),
      source: source,
    );
    expect(casablanca.any((e) => e.cityName == 'Rabat'), isFalse);
    expect(
      casablanca.any((e) => e.itemName.contains('Rabat-Salé')),
      isFalse,
    );

    final rabat = PriceObservationQuery.filter(
      const PriceIntelligenceQuery(cityName: 'Rabat'),
      source: source,
    );
    expect(rabat.any((e) => e.cityName == 'Casablanca'), isFalse);
    expect(
      rabat.any((e) => e.itemName.contains('tram/busway')),
      isFalse,
    );
  });

  test('pas de produit logique dupliqué dans un résultat ville', () {
    final source = PriceObservationCatalog.asObservations;
    for (final city in PriceObservationCatalog.wave1Cities) {
      final items = PriceObservationQuery.filter(
        PriceIntelligenceQuery(cityName: city),
        source: source,
      );
      final keys = items.map((e) => '${e.category.name}|${e.itemName}').toList();
      expect(
        keys.toSet().length,
        keys.length,
        reason: 'doublons pour $city: $keys',
      );
      expect(items.map((e) => e.id).toSet().length, items.length);
    }
  });

  test('compatible avec filtres repository Prix', () {
    final source = PriceObservationCatalog.asObservations;

    for (final city in PriceObservationCatalog.wave1Cities) {
      final items = PriceObservationQuery.filter(
        PriceIntelligenceQuery(cityName: city),
        source: source,
      );
      expect(items, isNotEmpty, reason: city);
      expect(
        items.every(
          (e) => e.verificationStatus == PriceVerificationStatus.verified,
        ),
        isTrue,
      );
    }

    final transport = PriceObservationQuery.filter(
      const PriceIntelligenceQuery(
        cityName: 'Casablanca',
        category: PriceIntelligenceCategory.publicTransport,
      ),
      source: source,
    );
    expect(transport, isNotEmpty);
    expect(transport.every((e) => !e.isNational), isTrue);

    final highlights = PriceObservationQuery.highlights(
      source: source,
      cityName: 'Rabat',
      limit: 5,
    );
    expect(highlights, isNotEmpty);
    expect(
      highlights.every(
        (e) => e.cityName == 'Rabat' || e.cityName == PriceNationalCity.name,
      ),
      isTrue,
    );

    final repo = ResilientPriceIntelligenceRepository(
      seedItems: source,
      fetchRemote: () async => source,
    );
    expect(repo.getAll(cityName: 'Marrakech'), isNotEmpty);
    expect(repo.availableCities, isNot(contains(PriceNationalCity.name)));
    expect(
      repo.search(
        const PriceIntelligenceQuery(
          category: PriceIntelligenceCategory.mobilePlans,
          cityName: 'Casablanca',
        ),
      ),
      isNotEmpty,
    );
  });

  test('ne réutilise pas les slugs legacy price-* du PriceCatalog', () {
    for (final entry in PriceObservationCatalog.entries) {
      expect(entry.slug.startsWith('price-'), isFalse);
    }
  });

  test('retiredNationalReplicaSlugs couvre les 27 anciennes réplications', () {
    expect(PriceObservationCatalog.retiredNationalReplicaSlugs.length, 27);
  });
}
