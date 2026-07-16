import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/editorial/editorial_catalog_load_state.dart';
import 'package:atlas/features/prices/data/local_price_repository.dart';
import 'package:atlas/features/prices/data/price_catalog.dart';
import 'package:atlas/features/prices/data/price_record_mapper.dart';
import 'package:atlas/features/prices/data/resilient_price_repository.dart';
import 'package:atlas/features/prices/domain/models/price_models.dart';

void main() {
  group('PriceRecordMapper', () {
    test('mappe une ligne complète y compris les champs optionnels', () {
      final guide = PriceRecordMapper.fromRow({
        'slug': 'price-taxi-test',
        'name': 'Course de taxi',
        'city_name': 'Marrakech',
        'category': 'transport',
        'category_label': 'Transport',
        'min_amount_mad': 20,
        'max_amount_mad': 50,
        'average_amount_mad': 30,
        'unit_label': 'trajet court',
        'summary': 'Trajet en ville',
        'price_factors': ['Distance'],
        'warning_signs': ['Compteur éteint'],
        'negotiation_tips': ['Insistez sur le compteur'],
        'icon_key': 'local_taxi_outlined',
        'source_note': 'Grille 2024',
        'is_tourist_trap': true,
        'last_updated_at': '2025-07-12T00:00:00.000Z',
      });

      expect(guide.id, 'price-taxi-test');
      expect(guide.category, PriceCategory.transport);
      expect(guide.minAmountMad, 20);
      expect(guide.maxAmountMad, 50);
      expect(guide.averageAmountMad, 30);
      expect(guide.isTouristTrap, isTrue);
      expect(guide.sourceNote, 'Grille 2024');
      expect(guide.icon, Icons.local_taxi_outlined);
      expect(guide.priceFactors, ['Distance']);
    });

    test('ignore les lignes malformées via tryFromRow', () {
      expect(PriceRecordMapper.tryFromRow(const {}), isNull);
      expect(
        PriceRecordMapper.tryFromRow(const {
          'slug': '',
          'name': 'Sans slug',
          'city_name': 'Marrakech',
          'category': 'transport',
          'category_label': 'Transport',
          'min_amount_mad': 10,
          'max_amount_mad': 20,
          'average_amount_mad': 15,
          'unit_label': 'trajet',
          'summary': 'Résumé',
          'last_updated_at': '2025-07-12T00:00:00.000Z',
        }),
        isNull,
      );
      expect(
        PriceRecordMapper.tryFromRow({
          'slug': 'price-ok',
          'name': 'OK',
          'city_name': 'Marrakech',
          'category': 'unknown-category',
          'category_label': 'Services',
          'min_amount_mad': 10,
          'max_amount_mad': 20,
          'average_amount_mad': 15,
          'unit_label': 'unité',
          'summary': 'Résumé',
          'last_updated_at': '2025-07-12T00:00:00.000Z',
        })?.category,
        PriceCategory.services,
      );
      expect(
        PriceRecordMapper.tryFromRow(const {
          'slug': 'price-bad-amount',
          'name': 'Montant invalide',
          'city_name': 'Marrakech',
          'category': 'transport',
          'category_label': 'Transport',
          'min_amount_mad': 'not-a-number',
          'max_amount_mad': 20,
          'average_amount_mad': 15,
          'unit_label': 'trajet',
          'summary': 'Résumé',
          'last_updated_at': '2025-07-12T00:00:00.000Z',
        }),
        isNull,
      );
    });

    test('tolère les optionnels absents et coerce les montants numériques', () {
      final guide = PriceRecordMapper.tryFromRow({
        'slug': 'price-minimal',
        'name': 'Minimal',
        'city_name': 'Rabat',
        'category': 'foodAndCafes',
        'category_label': 'Restauration & cafés',
        'min_amount_mad': 10.4,
        'max_amount_mad': '20',
        'average_amount_mad': 15,
        'unit_label': 'par personne',
        'summary': 'Résumé',
        'last_updated_at': DateTime.utc(2025, 7, 12),
      });

      expect(guide, isNotNull);
      expect(guide!.sourceNote, isNull);
      expect(guide.isTouristTrap, isFalse);
      expect(guide.priceFactors, isEmpty);
      expect(guide.warningSigns, isEmpty);
      expect(guide.negotiationTips, isEmpty);
      expect(guide.minAmountMad, 10);
      expect(guide.maxAmountMad, 20);
      expect(guide.category, PriceCategory.foodAndCafes);
    });
  });

  group('ResilientPriceRepository', () {
    test('sert le catalogue local immédiatement avant le refresh distant', () {
      final repository = ResilientPriceRepository(
        local: LocalPriceRepository(),
        fetchRemote: () async => const [],
      );

      expect(repository.loadState, EditorialCatalogLoadState.idle);
      expect(repository.isUsingRemote, isFalse);
      expect(repository.getAll(), isNotEmpty);
      expect(repository.findById('price-taxi-marrakech'), isNotNull);
      expect(repository.catalogLastReviewedAt, PriceCatalog.lastReviewedAt);
    });

    test('charge avec succès les données distantes', () async {
      final repository = ResilientPriceRepository(
        local: LocalPriceRepository(),
        fetchRemote: () async => [
          _guide(
            id: 'remote-price',
            name: 'Prix distant',
            lastUpdatedAt: DateTime.utc(2026, 1, 15),
          ),
        ],
      );

      await repository.warmUp();

      expect(repository.loadState, EditorialCatalogLoadState.success);
      expect(repository.isUsingRemote, isTrue);
      expect(repository.findById('remote-price')?.name, 'Prix distant');
      expect(repository.findById('price-taxi-marrakech'), isNull);
      expect(repository.catalogLastReviewedAt, DateTime.utc(2026, 1, 15));
    });

    test('retombe sur le local en error si le distant échoue', () async {
      final repository = ResilientPriceRepository(
        local: LocalPriceRepository(),
        fetchRemote: () async => throw Exception('network error'),
      );

      await repository.warmUp();

      expect(repository.loadState, EditorialCatalogLoadState.error);
      expect(repository.lastError, isA<Exception>());
      expect(repository.isUsingRemote, isFalse);
      expect(repository.findById('price-taxi-marrakech'), isNotNull);
      expect(repository.catalogLastReviewedAt, PriceCatalog.lastReviewedAt);
    });

    test('retombe sur le local en stale si le distant est vide', () async {
      final repository = ResilientPriceRepository(
        local: LocalPriceRepository(),
        fetchRemote: () async => const [],
      );

      await repository.warmUp();

      expect(repository.loadState, EditorialCatalogLoadState.stale);
      expect(repository.isUsingRemote, isFalse);
      expect(
        repository.getAll(cityName: 'Marrakech').map((guide) => guide.id),
        isNotEmpty,
      );
    });

    test('ignore les lignes distantes malformées sans casser le catalogue',
        () async {
      final repository = ResilientPriceRepository(
        local: LocalPriceRepository(),
        fetchRemote: () async {
          final rows = [
            <String, dynamic>{
              'slug': 'price-valid-remote',
              'name': 'Valide',
              'city_name': 'Marrakech',
              'category': 'transport',
              'category_label': 'Transport',
              'min_amount_mad': 20,
              'max_amount_mad': 50,
              'average_amount_mad': 30,
              'unit_label': 'trajet',
              'summary': 'OK',
              'last_updated_at': '2025-07-12T00:00:00.000Z',
            },
            <String, dynamic>{
              'slug': '',
              'name': 'Invalide',
            },
          ];
          return [
            for (final row in rows) ?PriceRecordMapper.tryFromRow(row),
          ];
        },
      );

      await repository.warmUp();

      expect(repository.loadState, EditorialCatalogLoadState.success);
      expect(repository.findById('price-valid-remote'), isNotNull);
      expect(repository.getAll().length, 1);
    });

    test('rafraîchit après le démarrage : local puis distant', () async {
      final gate = Completer<void>();
      final repository = ResilientPriceRepository(
        local: LocalPriceRepository(),
        fetchRemote: () async {
          await gate.future;
          return [
            _guide(
              id: 'price-taxi-marrakech',
              name: 'Taxi (cloud)',
              lastUpdatedAt: DateTime.utc(2026, 2, 1),
            ),
          ];
        },
      );

      expect(
        repository.findById('price-taxi-marrakech')!.name,
        'Course de taxi',
      );
      expect(repository.loadState, EditorialCatalogLoadState.idle);

      final pending = repository.warmUp();
      await Future<void>.delayed(Duration.zero);
      expect(repository.loadState, EditorialCatalogLoadState.loading);

      var notified = false;
      repository.addListener(() => notified = true);

      gate.complete();
      await pending;

      expect(repository.loadState, EditorialCatalogLoadState.success);
      expect(
        repository.findById('price-taxi-marrakech')!.name,
        'Taxi (cloud)',
      );
      expect(notified, isTrue);
    });

    test('conserve recherche, filtre catégorie, ville et navigation par slug',
        () async {
      final repository = ResilientPriceRepository(
        local: LocalPriceRepository(),
        fetchRemote: () async => PriceCatalog.guides,
      );

      await repository.warmUp();

      final filtered = repository.search(
        const PriceSearchQuery(
          cityName: 'Marrakech',
          category: PriceCategory.transport,
          text: 'taxi',
        ),
      );

      expect(filtered.any((guide) => guide.id == 'price-taxi-marrakech'), isTrue);
      expect(
        filtered.every((guide) => guide.category == PriceCategory.transport),
        isTrue,
      );
      expect(
        filtered.every(
          (guide) =>
              guide.cityName == 'Marrakech' ||
              guide.cityName == PriceNationalCity.name,
        ),
        isTrue,
      );

      expect(repository.findById('price-taxi-marrakech'), isNotNull);
      expect(repository.findById('price-ctm-bus'), isNotNull);
      expect(repository.categories, PriceCategory.values);
    });

    test('catalogLastReviewedAt prend le max distant après refresh', () async {
      final repository = ResilientPriceRepository(
        local: LocalPriceRepository(),
        fetchRemote: () async => [
          _guide(
            id: 'price-a',
            name: 'A',
            lastUpdatedAt: DateTime.utc(2026, 1, 1),
          ),
          _guide(
            id: 'price-b',
            name: 'B',
            lastUpdatedAt: DateTime.utc(2026, 3, 10),
          ),
        ],
      );

      expect(repository.catalogLastReviewedAt, PriceCatalog.lastReviewedAt);

      await repository.warmUp();

      expect(repository.catalogLastReviewedAt, DateTime.utc(2026, 3, 10));
    });

    test('couvre villes et prix nationaux après refresh distant', () async {
      final repository = ResilientPriceRepository(
        local: LocalPriceRepository(),
        fetchRemote: () async => [
          _guide(
            id: 'price-city',
            name: 'Prix ville',
            cityName: 'Casablanca',
          ),
          _guide(
            id: 'price-national',
            name: 'Prix national',
            cityName: PriceNationalCity.name,
            category: PriceCategory.transport,
            categoryLabel: 'Transport',
          ),
        ],
      );

      await repository.warmUp();

      expect(repository.isCityCovered('Casablanca'), isTrue);
      expect(repository.isCityCovered('Fès'), isFalse);
      expect(repository.resolveCityName('Casablanca'), 'Casablanca');

      final guides = repository.getAll(cityName: 'Casablanca');
      expect(guides.map((guide) => guide.id), containsAll([
        'price-city',
        'price-national',
      ]));
    });

    test('après échec distant, recherche et filtres restent locaux', () async {
      final repository = ResilientPriceRepository(
        local: LocalPriceRepository(),
        fetchRemote: () async => throw Exception('offline'),
      );

      await repository.warmUp();

      final casablanca = repository.search(
        const PriceSearchQuery(cityName: 'Casablanca'),
      );

      expect(casablanca, isNotEmpty);
      expect(
        casablanca.every(
          (guide) =>
              guide.cityName == 'Casablanca' ||
              guide.cityName == PriceNationalCity.name,
        ),
        isTrue,
      );
    });
  });
}

PriceGuide _guide({
  required String id,
  required String name,
  String cityName = 'Marrakech',
  PriceCategory category = PriceCategory.services,
  String categoryLabel = 'Services',
  DateTime? lastUpdatedAt,
}) {
  return PriceGuide(
    id: id,
    name: name,
    cityName: cityName,
    category: category,
    categoryLabel: categoryLabel,
    minAmountMad: 10,
    maxAmountMad: 20,
    averageAmountMad: 15,
    unitLabel: 'unité',
    summary: 'Résumé test',
    priceFactors: const ['Facteur'],
    warningSigns: const ['Alerte'],
    negotiationTips: const ['Conseil'],
    lastUpdatedAt: lastUpdatedAt ?? DateTime.utc(2025, 7, 12),
    icon: Icons.payments_outlined,
  );
}
