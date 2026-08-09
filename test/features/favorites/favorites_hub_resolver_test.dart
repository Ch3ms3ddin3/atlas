import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/domain/place_repository.dart';
import 'package:atlas/features/favorites/data/favorites_hub_resolver.dart';
import 'package:atlas/features/favorites/domain/favorite_entity_type.dart';
import 'package:atlas/features/favorites/domain/models/favorite_key.dart';
import 'package:atlas/features/prices/domain/price_intelligence_repository.dart';
import 'package:atlas/features/procedures/data/local_procedure_repository.dart';
import 'package:atlas/features/procedures/domain/procedure_repository.dart';

import '../prices/price_intelligence_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlaceRepository places;
  late ProcedureRepository procedures;
  late PriceIntelligenceRepository prices;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaceRepository.resetForTest();
    ProcedureRepository.resetForTest();
    PriceIntelligenceRepository.resetForTest();
    PlaceRepository.registerFactory(LocalPlaceRepository.new);
    ProcedureRepository.registerFactory(LocalProcedureRepository.new);
    registerPriceIntelligenceFixtures();
    places = PlaceRepository();
    procedures = ProcedureRepository();
    prices = PriceIntelligenceRepository();
  });

  tearDown(() {
    PlaceRepository.resetForTest();
    ProcedureRepository.resetForTest();
    PriceIntelligenceRepository.resetForTest();
  });

  test('resolves place, procedure and verified price from real catalogs', () {
    final entries = FavoritesHubResolver.resolve(
      activeFavorites: const [
        FavoriteKey(
          entityType: FavoriteEntityType.place,
          entitySlug: 'place-majorelle',
        ),
        FavoriteKey(
          entityType: FavoriteEntityType.procedure,
          entitySlug: 'cin-renewal',
        ),
        FavoriteKey(
          entityType: FavoriteEntityType.price,
          entitySlug: 'sp95-marrakech',
        ),
      ],
      places: places,
      procedures: procedures,
      prices: prices,
    );

    expect(entries, hasLength(3));
    expect(entries[0].title, 'Jardin Majorelle');
    expect(entries[0].isResolved, isTrue);
    expect(entries[1].title, 'Renouveler la CIN');
    expect(entries[1].isResolved, isTrue);
    expect(entries[2].title, 'SP95 Marrakech');
    expect(entries[2].isResolved, isTrue);
  });

  test('marks stale slugs unresolved without inventing titles', () {
    final entries = FavoritesHubResolver.resolve(
      activeFavorites: const [
        FavoriteKey(
          entityType: FavoriteEntityType.place,
          entitySlug: 'place-does-not-exist',
        ),
        FavoriteKey(
          entityType: FavoriteEntityType.procedure,
          entitySlug: 'procedure-gone',
        ),
        FavoriteKey(
          entityType: FavoriteEntityType.price,
          entitySlug: 'price-stale',
        ),
      ],
      places: places,
      procedures: procedures,
      prices: prices,
    );

    expect(entries.map((e) => e.isResolved), everyElement(isFalse));
    expect(entries[0].title, 'Lieu indisponible');
    expect(entries[0].subtitle, contains('place-does-not-exist'));
    expect(entries[1].title, 'Démarche indisponible');
    expect(entries[1].subtitle, contains('procedure-gone'));
    expect(entries[2].title, 'Prix indisponible');
    expect(entries[2].subtitle, contains('price-stale'));
  });

  test('sorts by type then resolved then title', () {
    final entries = FavoritesHubResolver.resolve(
      activeFavorites: const [
        FavoriteKey(
          entityType: FavoriteEntityType.price,
          entitySlug: 'sp95-marrakech',
        ),
        FavoriteKey(
          entityType: FavoriteEntityType.place,
          entitySlug: 'missing-place',
        ),
        FavoriteKey(
          entityType: FavoriteEntityType.place,
          entitySlug: 'place-majorelle',
        ),
        FavoriteKey(
          entityType: FavoriteEntityType.procedure,
          entitySlug: 'cin-renewal',
        ),
      ],
      places: places,
      procedures: procedures,
      prices: prices,
    );

    expect(entries.map((e) => e.entitySlug).toList(), [
      'place-majorelle',
      'missing-place',
      'cin-renewal',
      'sp95-marrakech',
    ]);
  });
}
