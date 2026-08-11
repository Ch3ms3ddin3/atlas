import 'package:atlas/core/editorial/editorial_catalog_load_state.dart';
import 'package:atlas/features/prices/data/price_intelligence_cache_store.dart';
import 'package:atlas/features/prices/data/price_observation_catalog.dart';
import 'package:atlas/features/prices/data/price_observation_mapper.dart';
import 'package:atlas/features/prices/data/price_observation_query.dart';
import 'package:atlas/features/prices/data/resilient_price_intelligence_repository.dart';
import 'package:atlas/features/prices/domain/models/price_models.dart';
import 'package:atlas/features/prices/domain/models/price_observation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'price_intelligence_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PriceObservationMapper', () {
    test('mappe une ligne vérifiée', () {
      final item = PriceObservationMapper.fromSupabaseRow({
        'slug': 'sp95-marrakech',
        'item_name': 'SP95 Marrakech',
        'category': 'fuel',
        'city_name': 'Marrakech',
        'unit_label': 'litre',
        'current_amount_mad': 12.45,
        'min_amount_mad': 12.2,
        'avg_amount_mad': 12.4,
        'max_amount_mad': 12.7,
        'currency': 'MAD',
        'last_updated_at': '2026-07-01T10:00:00Z',
        'source': 'Test',
        'confidence': 'high',
        'verification_status': 'verified',
        'user_reports_count': 2,
        'atlas_score': 80,
      });

      expect(item, isNotNull);
      expect(item!.currentAmountMad, 12.45);
      expect(item.verificationStatus, PriceVerificationStatus.verified);
    });

    test('refuse une ligne non vérifiée', () {
      final item = PriceObservationMapper.fromSupabaseRow({
        'slug': 'draft',
        'item_name': 'Draft',
        'category': 'fuel',
        'city_name': 'Marrakech',
        'unit_label': 'litre',
        'current_amount_mad': 10,
        'last_updated_at': '2026-07-01T10:00:00Z',
        'source': 'Test',
        'confidence': 'low',
        'verification_status': 'pending',
      });
      expect(item, isNull);
    });
  });

  group('PriceObservationQuery', () {
    test('trie par prix croissant', () {
      final items = List<PriceObservation>.from(
        PriceIntelligenceFixtures.sample,
      );
      PriceObservationQuery.sortInPlace(
        items,
        PriceIntelligenceSort.lowestPrice,
      );
      expect(items.first.itemName, 'Café noir');
    });

    test('highlights city-aware et diversifiés', () {
      final highlights = PriceObservationQuery.highlights(
        source: PriceIntelligenceFixtures.sample,
        cityName: 'Marrakech',
        limit: 3,
      );
      expect(highlights.length, 3);
      expect(
        highlights.every(
          (e) =>
              e.cityName == 'Marrakech' ||
              e.cityName == PriceNationalCity.name,
        ),
        isTrue,
      );
      final categories = highlights.map((e) => e.category).toSet();
      expect(categories.length, greaterThanOrEqualTo(2));
    });
  });

  group('ResilientPriceIntelligenceRepository', () {
    test('sert le distant vérifié', () async {
      final repo = ResilientPriceIntelligenceRepository(
        fetchRemote: () async => PriceIntelligenceFixtures.sample,
      );

      await repo.warmUp();
      expect(repo.loadState, EditorialCatalogLoadState.success);
      expect(repo.getAll(), isNotEmpty);
      expect(repo.findById('sp95-marrakech')?.itemName, 'SP95 Marrakech');
    });

    test('retombe en stale si le distant échoue avec seed', () async {
      final offline = ResilientPriceIntelligenceRepository(
        fetchRemote: () async => throw Exception('offline'),
        seedItems: PriceIntelligenceFixtures.sample,
      );
      await offline.warmUp();
      expect(offline.loadState, EditorialCatalogLoadState.stale);
      expect(offline.getAll(cityName: 'Marrakech'), isNotEmpty);
    });

    test(
      'premier lancement offline : catalogue bundlé Marrakech non vide',
      () async {
        final offline = ResilientPriceIntelligenceRepository(
          fetchRemote: () async => throw Exception('offline'),
          seedItems: PriceObservationCatalog.asObservations,
        );
        await offline.warmUp();

        expect(offline.loadState, EditorialCatalogLoadState.stale);
        expect(offline.isUsingCacheOnly, isTrue);

        final marrakech = offline.getAll(cityName: 'Marrakech');
        expect(marrakech, isNotEmpty);
        expect(
          marrakech.every(
            (e) =>
                e.verificationStatus == PriceVerificationStatus.verified &&
                (e.isNational || e.cityName == 'Marrakech'),
          ),
          isTrue,
        );
        expect(
          marrakech.any((e) => e.category == PriceIntelligenceCategory.mobilePlans),
          isTrue,
        );
        // Seed must not be written to disk until a successful remote fetch.
        final cache = const PriceIntelligenceCacheStore();
        expect(await cache.load(), isEmpty);
      },
    );

    test('cache distant prioritaire sur le seed au warmUp', () async {
      const cacheStore = PriceIntelligenceCacheStore();
      await cacheStore.save(PriceIntelligenceFixtures.sample);

      final repo = ResilientPriceIntelligenceRepository(
        cacheStore: cacheStore,
        fetchRemote: () async => throw Exception('offline'),
        seedItems: const [],
      );
      await repo.warmUp();

      expect(repo.findById('sp95-marrakech'), isNotNull);
      expect(repo.loadState, EditorialCatalogLoadState.stale);
    });

    test('succès vide sans inventer de prix', () async {
      final repo = ResilientPriceIntelligenceRepository(
        fetchRemote: () async => const [],
      );
      await repo.warmUp();
      expect(repo.loadState, EditorialCatalogLoadState.success);
      expect(repo.getAll(), isEmpty);
      expect(repo.highlights(cityName: 'Marrakech'), isEmpty);
    });

    test('remote non vide remplace le seed et remplit le cache', () async {
      final repo = ResilientPriceIntelligenceRepository(
        fetchRemote: () async => PriceIntelligenceFixtures.sample,
        seedItems: PriceObservationCatalog.asObservations,
      );
      await repo.warmUp();

      expect(repo.loadState, EditorialCatalogLoadState.success);
      expect(repo.findById('sp95-marrakech'), isNotNull);
      final cached = await const PriceIntelligenceCacheStore().load();
      expect(cached.any((e) => e.id == 'sp95-marrakech'), isTrue);
    });
  });
}
