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
              e.cityName == 'Marrakech' || e.cityName == PriceNationalCity.name,
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
          marrakech.any(
            (e) => e.category == PriceIntelligenceCategory.mobilePlans,
          ),
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
        seedItems: PriceObservationCatalog.asObservations,
      );
      await repo.warmUp();
      expect(repo.loadState, EditorialCatalogLoadState.success);
      expect(repo.getAll(), isEmpty);
      expect(repo.highlights(cityName: 'Marrakech'), isEmpty);
    });

    test('remote Wave 1 conserve le seed Wave 2 (merge par slug)', () async {
      final wave1Only = PriceObservationCatalog.asObservations
          .where((e) => e.category != PriceIntelligenceCategory.culture)
          .toList();
      expect(wave1Only, isNotEmpty);

      final repo = ResilientPriceIntelligenceRepository(
        fetchRemote: () async => wave1Only,
        seedItems: PriceObservationCatalog.asObservations,
      );
      await repo.warmUp();

      expect(repo.loadState, EditorialCatalogLoadState.success);
      final culture = repo.search(
        const PriceIntelligenceQuery(
          cityName: 'Marrakech',
          category: PriceIntelligenceCategory.culture,
        ),
      );
      expect(culture.length, 17);
      expect(repo.categories, contains(PriceIntelligenceCategory.culture));
      expect(
        repo.search(
          const PriceIntelligenceQuery(
            cityName: 'Marrakech',
            category: PriceIntelligenceCategory.mobilePlans,
          ),
        ),
        isNotEmpty,
      );
      expect(
        repo.findById('culture-palais-bahia-adulte-etranger-marrakech'),
        isNotNull,
      );

      final cached = await const PriceIntelligenceCacheStore().load();
      expect(
        cached.any((e) => e.category == PriceIntelligenceCategory.culture),
        isTrue,
      );
    });

    test('mergeRemoteOverSeed : distant gagne sur le même slug', () {
      final seed = PriceObservationCatalog.asObservations;
      final wave1 = seed
          .where((e) => e.category != PriceIntelligenceCategory.culture)
          .toList();
      final merged = ResilientPriceIntelligenceRepository.mergeRemoteOverSeed(
        seed: seed,
        remote: wave1,
      );
      expect(
        merged
            .where((e) => e.category == PriceIntelligenceCategory.culture)
            .length,
        17,
      );
      expect(merged.length, seed.length);
      expect(
        ResilientPriceIntelligenceRepository.mergeRemoteOverSeed(
          seed: seed,
          remote: const [],
        ),
        isEmpty,
      );

      final bahiaSeed = seed.firstWhere(
        (e) => e.id == 'culture-palais-bahia-adulte-etranger-marrakech',
      );
      final bahiaRemote = PriceObservation(
        id: bahiaSeed.id,
        itemName: bahiaSeed.itemName,
        category: bahiaSeed.category,
        cityName: bahiaSeed.cityName,
        unitLabel: bahiaSeed.unitLabel,
        currentAmountMad: 101,
        lastUpdatedAt: bahiaSeed.lastUpdatedAt,
        source: bahiaSeed.source,
        sourceUrl: bahiaSeed.sourceUrl,
        confidence: bahiaSeed.confidence,
        verificationStatus: bahiaSeed.verificationStatus,
        atlasScore: bahiaSeed.atlasScore,
      );
      final overridden =
          ResilientPriceIntelligenceRepository.mergeRemoteOverSeed(
            seed: seed,
            remote: [bahiaRemote, ...wave1],
          );
      expect(
        overridden.firstWhere((e) => e.id == bahiaSeed.id).currentAmountMad,
        101,
      );
    });

    test('remote non vide fusionne le seed et remplit le cache', () async {
      final repo = ResilientPriceIntelligenceRepository(
        fetchRemote: () async => PriceIntelligenceFixtures.sample,
        seedItems: PriceObservationCatalog.asObservations,
      );
      await repo.warmUp();

      expect(repo.loadState, EditorialCatalogLoadState.success);
      expect(repo.findById('sp95-marrakech'), isNotNull);
      expect(repo.findById('culture-macaal-adulte-marrakech'), isNotNull);
      final cached = await const PriceIntelligenceCacheStore().load();
      expect(cached.any((e) => e.id == 'sp95-marrakech'), isTrue);
      expect(
        cached.any((e) => e.id == 'culture-macaal-adulte-marrakech'),
        isTrue,
      );
    });

    test('cache Wave 1 offline fusionne le seed culture au warmUp', () async {
      const cacheStore = PriceIntelligenceCacheStore();
      final wave1Only = PriceObservationCatalog.asObservations
          .where((e) => e.category != PriceIntelligenceCategory.culture)
          .toList();
      await cacheStore.save(wave1Only);

      final repo = ResilientPriceIntelligenceRepository(
        cacheStore: cacheStore,
        fetchRemote: () async => throw Exception('offline'),
        seedItems: PriceObservationCatalog.asObservations,
      );
      await repo.warmUp();

      expect(
        repo
            .search(
              const PriceIntelligenceQuery(
                cityName: 'Marrakech',
                category: PriceIntelligenceCategory.culture,
              ),
            )
            .length,
        17,
      );
    });
  });
}
