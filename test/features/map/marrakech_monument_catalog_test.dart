import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/data/place_catalog.dart';
import 'package:atlas/features/explorer/data/place_mapper.dart';
import 'package:atlas/features/explorer/domain/models/place_models.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/map/data/map_place_query.dart';
import 'package:atlas/features/map/domain/atlas_map_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaceBrowseFilters.resetForTest();
  });

  tearDown(PlaceBrowseFilters.resetForTest);

  /// Five Marrakech `monument` records + YSL under `musee`.
  const monumentIds = <String>{
    'place-bahia',
    'place-koutoubia',
    'place-medersa-ben-youssef',
    'place-tombeaux-saadiens',
    'place-el-badi',
  };

  const packageIds = <String>{...monumentIds, 'place-ysl-museum'};

  const expectedCoords = <String, (double, double)>{
    'place-bahia': (31.621420, -7.982689),
    'place-koutoubia': (31.623751, -7.993358),
    'place-medersa-ben-youssef': (31.631984, -7.986036),
    'place-ysl-museum': (31.642543, -8.003420),
    'place-tombeaux-saadiens': (31.617259, -7.988555),
    'place-el-badi': (31.618966, -7.985704),
  };

  test('six V1 records exist once — no Bahia/YSL duplicates', () {
    final ids = PlaceCatalog.guides.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids, hasLength(41));
    for (final id in packageIds) {
      expect(ids.where((x) => x == id), hasLength(1));
    }
  });

  test('exact verified coordinates and categories', () {
    for (final entry in expectedCoords.entries) {
      final place = PlaceCatalog.guides.firstWhere((p) => p.id == entry.key);
      expect(place.cityName, 'Marrakech');
      expect(place.hasCoordinates, isTrue);
      expect(place.latitude, entry.value.$1);
      expect(place.longitude, entry.value.$2);
      expect(place.latitude!.isFinite, isTrue);
      expect(place.longitude!.isFinite, isTrue);
      expect(
        place.mapsUrl,
        'https://www.google.com/maps/search/?api=1&query='
        '${entry.value.$1.toStringAsFixed(6)},'
        '${entry.value.$2.toStringAsFixed(6)}',
      );
      final storageCovered = {
        'place-koutoubia',
        'place-medersa-ben-youssef',
        'place-tombeaux-saadiens',
        'place-el-badi',
      };
      if (storageCovered.contains(entry.key)) {
        expect(place.hasPrimaryImage, isTrue);
        expect(
          place.primaryImageUrl,
          contains('place-photos/${entry.key}/cover.webp'),
        );
      } else {
        expect(place.imageUrls, isEmpty);
      }
    }

    expect(
      PlaceCatalog.guides
          .firstWhere((p) => p.id == 'place-ysl-museum')
          .category,
      PlaceCategory.musee,
    );
    for (final id in monumentIds) {
      expect(
        PlaceCatalog.guides.firstWhere((p) => p.id == id).category,
        PlaceCategory.monument,
      );
    }
  });

  test('Atlas Selection: all five Marrakech monuments in beta core', () {
    final monumentSelections = PlaceCatalog.guides.where(
      (p) =>
          p.cityName == 'Marrakech' &&
          p.category == PlaceCategory.monument &&
          p.isEditorsPick,
    );
    expect(monumentSelections, hasLength(5));
    expect(monumentSelections.map((p) => p.id).toSet(), monumentIds);

    final ysl = PlaceCatalog.guides.firstWhere(
      (p) => p.id == 'place-ysl-museum',
    );
    expect(ysl.isEditorsPick, isTrue);

    final majorelle = PlaceCatalog.guides.firstWhere(
      (p) => p.id == 'place-majorelle',
    );
    expect(majorelle.category, PlaceCategory.jardin);
    expect(majorelle.isEditorsPick, isTrue);
    expect(majorelle.neighborhood, 'Guéliz');
  });

  test(
    'Koutoubia stays exterior-honest; Dar El Bacha museum is Musée not Monument',
    () {
      final koutoubia = PlaceCatalog.guides.firstWhere(
        (p) => p.id == 'place-koutoubia',
      );
      expect(koutoubia.summary.toLowerCase(), contains('extérieur'));
      expect(
        koutoubia.practicalTips.join(' ').toLowerCase(),
        contains('non-musulmans'),
      );
      expect(koutoubia.website, isNull);

      final museum = PlaceCatalog.guides.firstWhere(
        (p) => p.id == 'place-musee-dar-el-bacha',
      );
      expect(museum.category, PlaceCategory.musee);
      expect(
        PlaceCatalog.guides.any((p) => p.id == 'place-dar-el-bacha'),
        isFalse,
      );
    },
  );

  test('restaurants and cafés remain unaffected', () {
    expect(
      PlaceCatalog.guides.where(
        (p) =>
            p.cityName == 'Marrakech' && p.category == PlaceCategory.restaurant,
      ),
      hasLength(11),
    );
    expect(
      PlaceCatalog.guides.where(
        (p) => p.cityName == 'Marrakech' && p.category == PlaceCategory.cafe,
      ),
      hasLength(5),
    );
  });

  test(
    'Explorer: Marrakech + Monument returns exactly the 5 monument records',
    () {
      final results = PlaceMapper.filter(
        const PlaceSearchQuery(
          cityName: 'Marrakech',
          category: PlaceCategory.monument,
        ),
      );
      expect(results.map((p) => p.id).toSet(), monumentIds);
      expect(results, hasLength(5));
      expect(results.any((p) => p.id == 'place-ysl-museum'), isFalse);
      expect(results.any((p) => p.id == 'place-majorelle'), isFalse);
    },
  );

  test('Explorer: Marrakech Toutes includes all six package records', () {
    final results = PlaceMapper.filter(
      const PlaceSearchQuery(cityName: 'Marrakech'),
    );
    final ids = results.map((p) => p.id).toSet();
    expect(ids, containsAll(packageIds));
  });

  test('search monument and each name (accent-tolerant)', () {
    final byCategory = PlaceMapper.filter(
      const PlaceSearchQuery(cityName: 'Marrakech', text: 'monument'),
    );
    expect(byCategory.map((p) => p.id).toSet(), monumentIds);

    final names = <String, String>{
      'bahia': 'place-bahia',
      'koutoubia': 'place-koutoubia',
      'médersa': 'place-medersa-ben-youssef',
      'medersa': 'place-medersa-ben-youssef',
      'yves saint laurent': 'place-ysl-museum',
      'tombeaux': 'place-tombeaux-saadiens',
      'el badi': 'place-el-badi',
    };
    for (final entry in names.entries) {
      final hits = PlaceMapper.filter(
        PlaceSearchQuery(cityName: 'Marrakech', text: entry.key),
      );
      expect(
        hits.map((p) => p.id),
        contains(entry.value),
        reason: 'search «${entry.key}»',
      );
    }
  });

  test('Carte Monument filter matches Explorer set with valid markers', () {
    final filters = PlaceBrowseFilters.instance
      ..setCityName('Marrakech', notify: false)
      ..setCategory(PlaceCategory.monument, notify: false);
    final markers = MapPlaceQuery.markers(
      repository: LocalPlaceRepository(),
      filters: filters,
    );
    expect(markers.map((m) => m.placeId).toSet(), monumentIds);
    expect(markers, hasLength(5));
    for (final marker in markers) {
      expect(marker.latitude.isFinite, isTrue);
      expect(marker.longitude.isFinite, isTrue);
      final expected = expectedCoords[marker.placeId]!;
      expect(marker.latitude, expected.$1);
      expect(marker.longitude, expected.$2);
      final rebuilt = AtlasMapMarker.fromPlace(
        PlaceCatalog.guides.firstWhere((p) => p.id == marker.placeId),
        isFavorite: false,
      );
      expect(rebuilt, isNotNull);
      expect(rebuilt!.placeId, marker.placeId);
    }
  });

  test('Carte Toutes includes YSL marker with verified coords', () {
    final filters = PlaceBrowseFilters.instance
      ..setCityName('Marrakech', notify: false)
      ..setCategory(null, notify: false);
    final markers = MapPlaceQuery.markers(
      repository: LocalPlaceRepository(),
      filters: filters,
    );
    final ids = markers.map((m) => m.placeId).toSet();
    expect(ids, containsAll(packageIds));
    final ysl = markers.firstWhere((m) => m.placeId == 'place-ysl-museum');
    expect(ysl.latitude, 31.642543);
    expect(ysl.longitude, -8.003420);
  });
}
