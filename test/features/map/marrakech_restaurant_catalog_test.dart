import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/data/place_catalog.dart';
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

  const expectedRestaurants = <String, ({double lat, double lng, bool selection})>{
    'place-al-fassia-gueliz': (
      lat: 31.635992,
      lng: -8.013364,
      selection: true,
    ),
    'place-amal-gueliz': (
      lat: 31.639072,
      lng: -8.013756,
      selection: false,
    ),
    'place-nomad': (
      lat: 31.628593,
      lng: -7.987530,
      selection: false,
    ),
    'place-plus61': (
      lat: 31.635162,
      lng: -8.015502,
      selection: false,
    ),
    'place-le-jardin': (
      lat: 31.632074,
      lng: -7.988806,
      selection: false,
    ),
  };

  const expectedHammams = <String>{
    'place-les-bains-marrakech',
    'place-hammam-de-la-rose',
    'place-heritage-spa',
    'place-hammam-place-des-epices',
  };

  test('five verified Marrakech restaurants exist with unique IDs', () {
    final ids = PlaceCatalog.guides.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final id in expectedRestaurants.keys) {
      expect(ids, contains(id));
    }
    expect(
      PlaceCatalog.guides.where(
        (p) =>
            p.cityName == 'Marrakech' &&
            p.category == PlaceCategory.restaurant,
      ),
      hasLength(5),
    );
  });

  test('exact verified coordinates and selection flags', () {
    for (final entry in expectedRestaurants.entries) {
      final place = PlaceCatalog.guides.firstWhere((p) => p.id == entry.key);
      expect(place.cityName, 'Marrakech');
      expect(place.category, PlaceCategory.restaurant);
      expect(place.categoryLabel, 'Restaurant');
      expect(place.hasCoordinates, isTrue);
      expect(place.latitude, entry.value.lat);
      expect(place.longitude, entry.value.lng);
      expect(place.isEditorsPick, entry.value.selection);
      expect(place.address, isNotNull);
      expect(place.address!.trim(), isNotEmpty);
      expect(place.imageUrls, isEmpty);
    }
    expect(
      PlaceCatalog.guides.where(
        (p) =>
            p.isEditorsPick &&
            p.cityName == 'Marrakech' &&
            p.category == PlaceCategory.restaurant,
      ),
      hasLength(1),
    );
    expect(
      PlaceCatalog.guides
          .firstWhere((p) => p.id == 'place-al-fassia-gueliz')
          .isEditorsPick,
      isTrue,
    );
  });

  test('branch identity guards (Guéliz / Le Jardin naming)', () {
    final fassia = PlaceCatalog.guides.firstWhere(
      (p) => p.id == 'place-al-fassia-gueliz',
    );
    expect(fassia.name, 'Al Fassia Guéliz');
    expect(fassia.address!.toLowerCase(), contains('zerktouni'));
    expect(fassia.summary.toLowerCase(), isNot(contains('ourika')));
    expect(fassia.summary.toLowerCase(), contains('aguedal'));

    final amal = PlaceCatalog.guides.firstWhere(
      (p) => p.id == 'place-amal-gueliz',
    );
    expect(amal.name, 'Restaurant Amal Guéliz');
    expect(amal.address!.toLowerCase(), contains('allal ben ahmed'));
    expect(
      amal.practicalTips.any((t) => t.toLowerCase().contains('targa')),
      isTrue,
    );

    final jardin = PlaceCatalog.guides.firstWhere(
      (p) => p.id == 'place-le-jardin',
    );
    expect(jardin.name, 'Le Jardin');
    expect(jardin.name, isNot(contains('Jardins de la Medina')));
    expect(
      jardin.practicalTips.any(
        (t) => t.contains('Les Jardins de la Medina'),
      ),
      isTrue,
    );

    final plus61 = PlaceCatalog.guides.firstWhere(
      (p) => p.id == 'place-plus61',
    );
    expect(plus61.name, 'Plus61');
    expect(plus61.address!.toLowerCase(), contains('beqal'));
  });

  test('Marrakech + restaurant returns exactly the five curated restaurants', () {
    final filters = PlaceBrowseFilters.instance
      ..setCityName('Marrakech', notify: false)
      ..setCategory(PlaceCategory.restaurant, notify: false);
    final markers = MapPlaceQuery.markers(
      repository: LocalPlaceRepository(),
      filters: filters,
    );
    expect(markers, hasLength(5));
    expect(
      markers.every((m) => m.category == PlaceCategory.restaurant),
      isTrue,
    );
    expect(
      markers.map((m) => m.placeId).toSet(),
      expectedRestaurants.keys.toSet(),
    );
    expect(
      markers.any((m) => m.placeId == 'place-marche-central'),
      isFalse,
    );
  });

  test('text search restaurant finds Marrakech curated set', () {
    final repo = LocalPlaceRepository();
    final filters = PlaceBrowseFilters.instance
      ..setCityName('Marrakech', notify: false)
      ..setSearchText('restaurant', notify: false);
    final markers = MapPlaceQuery.markers(repository: repo, filters: filters);
    expect(
      markers.map((m) => m.placeId).toSet(),
      expectedRestaurants.keys.toSet(),
    );
  });

  test('existing Marrakech hammams remain intact', () {
    for (final id in expectedHammams) {
      final place = PlaceCatalog.guides.firstWhere((p) => p.id == id);
      expect(place.cityName, 'Marrakech');
      expect(place.category, PlaceCategory.hammam);
      expect(place.hasCoordinates, isTrue);
    }
    final filters = PlaceBrowseFilters.instance
      ..setCityName('Marrakech', notify: false)
      ..setCategory(PlaceCategory.hammam, notify: false);
    final markers = MapPlaceQuery.markers(
      repository: LocalPlaceRepository(),
      filters: filters,
    );
    expect(markers.map((m) => m.placeId).toSet(), expectedHammams);
  });

  test('Casablanca Marché Central remains untouched', () {
    final marche = PlaceCatalog.guides.firstWhere(
      (p) => p.id == 'place-marche-central',
    );
    expect(marche.name, 'Marché Central');
    expect(marche.cityName, 'Casablanca');
    expect(marche.category, PlaceCategory.restaurant);
    expect(marche.latitude, 33.594);
    expect(marche.longitude, -7.618);
    expect(marche.isEditorsPick, isTrue);
    expect(marche.phone, isNull);
    expect(marche.website, isNull);
    expect(marche.address, isNull);
  });

  test('rejected or deferred restaurants are absent', () {
    expect(
      PlaceCatalog.guides.any((p) => p.id == 'place-lmida'),
      isFalse,
    );
    expect(
      PlaceCatalog.guides.any((p) => p.name == "L'Mida"),
      isFalse,
    );
    expect(
      PlaceCatalog.guides.any((p) => p.name == 'Les Jardins de la Medina'),
      isFalse,
    );
  });
}
