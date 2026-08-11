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

  const expectedCafes = <String, ({double lat, double lng, bool selection})>{
    'place-bacha-coffee': (
      lat: 31.631521,
      lng: -7.992561,
      selection: true,
    ),
    'place-simple-specialty-coffee': (
      lat: 31.631583,
      lng: -7.990912,
      selection: false,
    ),
    'place-cafe-des-epices': (
      lat: 31.629062,
      lng: -7.987323,
      selection: false,
    ),
    'place-kartell-kollektiv': (
      lat: 31.636385,
      lng: -8.009579,
      selection: false,
    ),
    'place-cafe-clock': (
      lat: 31.613029,
      lng: -7.987289,
      selection: false,
    ),
  };

  const expectedRestaurants = <String>{
    'place-al-fassia-gueliz',
    'place-amal-gueliz',
    'place-nomad',
    'place-plus61',
    'place-le-jardin',
  };

  const expectedHammams = <String>{
    'place-les-bains-marrakech',
    'place-hammam-de-la-rose',
    'place-heritage-spa',
    'place-hammam-place-des-epices',
  };

  test('five verified Marrakech cafés exist with unique IDs', () {
    final ids = PlaceCatalog.guides.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final id in expectedCafes.keys) {
      expect(ids, contains(id));
    }
    expect(
      PlaceCatalog.guides.where(
        (p) =>
            p.cityName == 'Marrakech' && p.category == PlaceCategory.cafe,
      ),
      hasLength(5),
    );
  });

  test('exact verified coordinates and Bacha-only Atlas Selection', () {
    for (final entry in expectedCafes.entries) {
      final place = PlaceCatalog.guides.firstWhere((p) => p.id == entry.key);
      expect(place.cityName, 'Marrakech');
      expect(place.category, PlaceCategory.cafe);
      expect(place.categoryLabel, 'Café');
      expect(place.hasCoordinates, isTrue);
      expect(place.latitude, entry.value.lat);
      expect(place.longitude, entry.value.lng);
      expect(place.isEditorsPick, entry.value.selection);
      expect(place.address, isNotNull);
      expect(place.address!.trim(), isNotEmpty);
      expect(place.imageUrls, isEmpty);
      expect(
        place.mapsUrl,
        'https://www.google.com/maps/search/?api=1&query='
        '${entry.value.lat},${entry.value.lng}',
      );
    }

    final cafeSelections = PlaceCatalog.guides.where(
      (p) =>
          p.isEditorsPick &&
          p.cityName == 'Marrakech' &&
          p.category == PlaceCategory.cafe,
    );
    expect(cafeSelections, hasLength(1));
    expect(cafeSelections.single.id, 'place-bacha-coffee');
    expect(cafeSelections.single.name, 'Bacha Coffee');
  });

  test('sparse contact fields stay empty when unverified', () {
    final simple = PlaceCatalog.guides.firstWhere(
      (p) => p.id == 'place-simple-specialty-coffee',
    );
    expect(simple.phone, isNull);
    expect(simple.website, isNull);
    expect(simple.hasOpeningHours, isFalse);

    final kartell = PlaceCatalog.guides.firstWhere(
      (p) => p.id == 'place-kartell-kollektiv',
    );
    expect(kartell.phone, isNull);
    expect(kartell.hasOpeningHours, isFalse);
    expect(kartell.website, 'https://kartell.space/');
    expect(kartell.neighborhood, 'Guéliz');
  });

  test('Thirty5ive and deferred cafés are absent', () {
    expect(
      PlaceCatalog.guides.any((p) => p.id == 'place-thirty5ive'),
      isFalse,
    );
    expect(
      PlaceCatalog.guides.any(
        (p) => p.name.toLowerCase().contains('thirty5ive'),
      ),
      isFalse,
    );
    expect(
      PlaceCatalog.guides.any((p) => p.name.toLowerCase().contains('kosykawa')),
      isFalse,
    );
    expect(
      PlaceCatalog.guides.any((p) => p.name.toLowerCase() == 'kaizen'),
      isFalse,
    );
  });

  test('Marrakech + Café returns exactly the five curated cafés', () {
    final filters = PlaceBrowseFilters.instance
      ..setCityName('Marrakech', notify: false)
      ..setCategory(PlaceCategory.cafe, notify: false);
    final markers = MapPlaceQuery.markers(
      repository: LocalPlaceRepository(),
      filters: filters,
    );
    expect(markers, hasLength(5));
    expect(markers.every((m) => m.category == PlaceCategory.cafe), isTrue);
    expect(markers.map((m) => m.placeId).toSet(), expectedCafes.keys.toSet());
  });

  test('search café / coffee / establishment names', () {
    final cafeHits = PlaceMapper.filter(
      const PlaceSearchQuery(
        text: 'café',
        cityName: 'Marrakech',
        strictCity: true,
      ),
    );
    expect(cafeHits.map((p) => p.id).toSet(), expectedCafes.keys.toSet());

    final coffeeHits = PlaceMapper.filter(
      const PlaceSearchQuery(
        text: 'coffee',
        cityName: 'Marrakech',
        strictCity: true,
      ),
    );
    expect(coffeeHits.map((p) => p.id).toSet(), expectedCafes.keys.toSet());

    for (final name in [
      'Bacha Coffee',
      'Simple Specialty Coffee',
      'Café des Épices',
      'Kartell Kollektiv',
      'Café Clock',
    ]) {
      final byName = PlaceMapper.filter(
        PlaceSearchQuery(
          text: name,
          cityName: 'Marrakech',
          strictCity: true,
        ),
      );
      expect(byName, isNotEmpty);
      expect(byName.any((p) => p.name == name), isTrue);
    }
  });

  test('existing Marrakech restaurants and hammams remain intact', () {
    expect(
      PlaceCatalog.guides.where(
        (p) =>
            p.cityName == 'Marrakech' &&
            p.category == PlaceCategory.restaurant,
      ).map((p) => p.id).toSet(),
      expectedRestaurants,
    );
    expect(
      PlaceCatalog.guides.where(
        (p) =>
            p.cityName == 'Marrakech' && p.category == PlaceCategory.hammam,
      ).map((p) => p.id).toSet(),
      expectedHammams,
    );

    final restaurantMarkers = MapPlaceQuery.markers(
      repository: LocalPlaceRepository(),
      filters: PlaceBrowseFilters.instance
        ..setCityName('Marrakech', notify: false)
        ..setCategory(PlaceCategory.restaurant, notify: false),
    );
    expect(
      restaurantMarkers.map((m) => m.placeId).toSet(),
      expectedRestaurants,
    );

    final hammamMarkers = MapPlaceQuery.markers(
      repository: LocalPlaceRepository(),
      filters: PlaceBrowseFilters.instance
        ..setCityName('Marrakech', notify: false)
        ..setCategory(PlaceCategory.hammam, notify: false),
    );
    expect(hammamMarkers.map((m) => m.placeId).toSet(), expectedHammams);
  });

  test('Café category is present for Marrakech inventory', () {
    expect(
      PlaceMapper.categoriesPresentIn(PlaceCatalog.guides),
      contains(PlaceCategory.cafe),
    );
    expect(
      LocalPlaceRepository().categories,
      contains(PlaceCategory.cafe),
    );
  });
}
