import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/data/place_catalog.dart';
import 'package:atlas/features/explorer/data/place_mapper.dart';
import 'package:atlas/features/explorer/domain/models/place_models.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/map/data/map_place_query.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaceBrowseFilters.resetForTest();
  });

  tearDown(PlaceBrowseFilters.resetForTest);

  const expectedMuseums = <String, ({double lat, double lng, bool selection})>{
    'place-ysl-museum': (lat: 31.642543, lng: -8.003420, selection: true),
    'place-musee-dar-el-bacha': (
      lat: 31.631387,
      lng: -7.992353,
      selection: true,
    ),
    'place-maison-de-la-photographie': (
      lat: 31.631986,
      lng: -7.984367,
      selection: true,
    ),
    'place-macaal': (lat: 31.600067, lng: -7.949914, selection: true),
  };

  test('four Marrakech musées V1 exist once with unique IDs', () {
    final ids = PlaceCatalog.guides.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids, hasLength(41));
    for (final id in expectedMuseums.keys) {
      expect(ids.where((x) => x == id), hasLength(1));
    }
    expect(
      PlaceCatalog.guides.where(
        (p) => p.cityName == 'Marrakech' && p.category == PlaceCategory.musee,
      ),
      hasLength(4),
    );
  });

  test('exact verified coordinates and musée beta Selection', () {
    for (final entry in expectedMuseums.entries) {
      final place = PlaceCatalog.guides.firstWhere((p) => p.id == entry.key);
      expect(place.cityName, 'Marrakech');
      expect(place.category, PlaceCategory.musee);
      expect(place.categoryLabel, 'Musée');
      expect(place.latitude, entry.value.lat);
      expect(place.longitude, entry.value.lng);
      expect(place.isEditorsPick, entry.value.selection);
      expect(place.hasCoordinates, isTrue);
      expect(place.latitude!.isFinite, isTrue);
      expect(place.longitude!.isFinite, isTrue);
      if (entry.key == 'place-musee-dar-el-bacha') {
        expect(place.hasPrimaryImage, isTrue);
        expect(
          place.primaryImageUrl,
          contains('place-photos/place-musee-dar-el-bacha/cover.webp'),
        );
      } else {
        expect(place.imageUrls, isEmpty);
      }
    }
    expect(
      PlaceCatalog.guides.where(
        (p) =>
            p.cityName == 'Marrakech' &&
            p.category == PlaceCategory.musee &&
            p.isEditorsPick,
      ),
      hasLength(4),
    );
    expect(
      PlaceCatalog.guides
          .firstWhere((p) => p.id == 'place-macaal')
          .isEditorsPick,
      isTrue,
    );
  });

  test('Dar El Bacha museum stays distinct from Bacha Coffee', () {
    final museum = PlaceCatalog.guides.firstWhere(
      (p) => p.id == 'place-musee-dar-el-bacha',
    );
    final coffee = PlaceCatalog.guides.firstWhere(
      (p) => p.id == 'place-bacha-coffee',
    );
    expect(museum.category, PlaceCategory.musee);
    expect(coffee.category, PlaceCategory.cafe);
    expect(museum.id, isNot(coffee.id));
    expect(museum.latitude, isNot(coffee.latitude));
    expect(
      museum.practicalTips.join(' ').toLowerCase(),
      contains('salon bacha'),
    );
    expect(museum.name, contains('Confluences'));
  });

  test('Majorelle remains Jardin; Berber museum not added', () {
    final majorelle = PlaceCatalog.guides.firstWhere(
      (p) => p.id == 'place-majorelle',
    );
    expect(majorelle.category, PlaceCategory.jardin);
    expect(
      PlaceCatalog.guides.any(
        (p) =>
            p.name.contains('Pierre Bergé') ||
            p.name.contains('arts berbères') ||
            p.id == 'place-musee-berbere',
      ),
      isFalse,
    );
  });

  test('Explorer: Marrakech + Musée returns exactly the 4 curated museums', () {
    final results = PlaceMapper.filter(
      const PlaceSearchQuery(
        cityName: 'Marrakech',
        category: PlaceCategory.musee,
      ),
    );
    expect(results.map((p) => p.id).toSet(), expectedMuseums.keys.toSet());
    expect(results, hasLength(4));
  });

  test('Carte Musée filter matches Explorer with valid markers', () {
    final filters = PlaceBrowseFilters.instance
      ..setCityName('Marrakech', notify: false)
      ..setCategory(PlaceCategory.musee, notify: false);
    final markers = MapPlaceQuery.markers(
      repository: LocalPlaceRepository(),
      filters: filters,
    );
    expect(markers.map((m) => m.placeId).toSet(), expectedMuseums.keys.toSet());
    expect(markers, hasLength(4));
    for (final marker in markers) {
      expect(marker.latitude.isFinite, isTrue);
      expect(marker.longitude.isFinite, isTrue);
      final expected = expectedMuseums[marker.placeId]!;
      expect(marker.latitude, expected.lat);
      expect(marker.longitude, expected.lng);
    }
  });

  test('search musée / museum names (accent-tolerant)', () {
    final byCategory = PlaceMapper.filter(
      const PlaceSearchQuery(cityName: 'Marrakech', text: 'musée'),
    );
    expect(byCategory.map((p) => p.id).toSet(), expectedMuseums.keys.toSet());

    final names = <String, String>{
      'yves saint laurent': 'place-ysl-museum',
      'confluences': 'place-musee-dar-el-bacha',
      'photographie': 'place-maison-de-la-photographie',
      'macaal': 'place-macaal',
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

  test('restaurants cafés monuments remain unaffected', () {
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
    expect(
      PlaceCatalog.guides.where(
        (p) =>
            p.cityName == 'Marrakech' && p.category == PlaceCategory.monument,
      ),
      hasLength(5),
    );
  });

  test('held museums stay out of V1', () {
    expect(
      PlaceCatalog.guides.any((p) => p.id == 'place-dar-si-said'),
      isFalse,
    );
    expect(
      PlaceCatalog.guides.any((p) => p.id == 'place-musee-de-marrakech'),
      isFalse,
    );
    expect(PlaceCatalog.guides.any((p) => p.id == 'place-tiskiwin'), isFalse);
  });
}
