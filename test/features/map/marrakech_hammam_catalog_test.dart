import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/data/place_catalog.dart';
import 'package:atlas/features/explorer/domain/models/place_models.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/domain/favorite_entity_type.dart';
import 'package:atlas/features/map/data/map_place_query.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaceBrowseFilters.resetForTest();
  });

  tearDown(PlaceBrowseFilters.resetForTest);

  const expectedHammams = <String, ({double lat, double lng, bool selection})>{
    'place-les-bains-marrakech': (
      lat: 31.617286,
      lng: -7.990510,
      selection: true,
    ),
    'place-hammam-de-la-rose': (
      lat: 31.631655,
      lng: -7.991533,
      selection: false,
    ),
    'place-heritage-spa': (
      lat: 31.630931,
      lng: -7.994706,
      selection: false,
    ),
    'place-hammam-place-des-epices': (
      lat: 31.628455,
      lng: -7.987441,
      selection: false,
    ),
  };

  test('generic Hammam traditionnel is removed from catalog', () {
    expect(
      PlaceCatalog.guides.any((p) => p.id == 'place-hammam-marrakech'),
      isFalse,
    );
    expect(
      PlaceCatalog.guides.any((p) => p.name == 'Hammam traditionnel'),
      isFalse,
    );
  });

  test('unverified Le Bain de Kasbah is removed from catalog', () {
    expect(
      PlaceCatalog.guides.any((p) => p.id == 'place-bain-de-kasbah'),
      isFalse,
    );
    expect(
      PlaceCatalog.guides.any((p) => p.name == 'Le Bain de Kasbah'),
      isFalse,
    );
  });

  test('four verified Marrakech hammams have exact coordinates', () {
    for (final entry in expectedHammams.entries) {
      final place = PlaceCatalog.guides.firstWhere((p) => p.id == entry.key);
      expect(place.cityName, 'Marrakech');
      expect(place.category, PlaceCategory.hammam);
      expect(place.hasCoordinates, isTrue);
      expect(place.latitude, entry.value.lat);
      expect(place.longitude, entry.value.lng);
      expect(place.isEditorsPick, entry.value.selection);
      expect(place.address, isNotNull);
      expect(place.address!.trim(), isNotEmpty);
    }
    expect(
      PlaceCatalog.guides.where(
        (p) => p.isEditorsPick && p.category == PlaceCategory.hammam,
      ),
      hasLength(1),
    );
    expect(
      PlaceCatalog.guides
          .firstWhere((p) => p.id == 'place-les-bains-marrakech')
          .isEditorsPick,
      isTrue,
    );
  });

  test('Carte markers include all curated hammams for Marrakech', () {
    final filters = PlaceBrowseFilters.instance
      ..setCityName('Marrakech', notify: false);
    final markers = MapPlaceQuery.markers(
      repository: LocalPlaceRepository(),
      filters: filters,
    );
    for (final id in expectedHammams.keys) {
      expect(markers.any((m) => m.placeId == id), isTrue, reason: id);
    }
    expect(
      markers.any((m) => m.placeId == 'place-bain-de-kasbah'),
      isFalse,
    );
  });

  test('category filter Hammam returns only the four verified hammams', () {
    final filters = PlaceBrowseFilters.instance
      ..setCityName('Marrakech', notify: false)
      ..setCategory(PlaceCategory.hammam, notify: false);
    final markers = MapPlaceQuery.markers(
      repository: LocalPlaceRepository(),
      filters: filters,
    );
    expect(markers, hasLength(4));
    expect(markers.every((m) => m.category == PlaceCategory.hammam), isTrue);
    expect(
      markers.map((m) => m.placeId).toSet(),
      expectedHammams.keys.toSet(),
    );
  });

  test('text + accent-insensitive search finds hammams', () {
    final repo = LocalPlaceRepository();
    final filters = PlaceBrowseFilters.instance
      ..setCityName('Marrakech', notify: false);

    List<String> idsFor(String query) {
      filters.setSearchText(query, notify: false);
      return MapPlaceQuery.markers(repository: repo, filters: filters)
          .map((m) => m.placeId)
          .toList()
        ..sort();
    }

    final hammamHits = idsFor('hammam');
    expect(hammamHits.toSet(), expectedHammams.keys.toSet());
    expect(hammamHits, isNot(contains('place-bain-de-kasbah')));

    expect(idsFor('bains'), contains('place-les-bains-marrakech'));
    expect(idsFor('rose'), contains('place-hammam-de-la-rose'));
    expect(idsFor('heritage'), contains('place-heritage-spa'));
    expect(idsFor('epices'), contains('place-hammam-place-des-epices'));
    expect(idsFor('épices'), idsFor('epices'));
    expect(idsFor('EPICES'), idsFor('épices'));
  });

  test('favorites filter works with curated hammam marker', () async {
    final favorites = LocalFavoritesRepository();
    await favorites.load();
    await favorites.addFavorite(
      entityType: FavoriteEntityType.place,
      entitySlug: 'place-les-bains-marrakech',
    );

    final filters = PlaceBrowseFilters.instance
      ..setCityName('Marrakech', notify: false)
      ..setFavoritesOnly(true, notify: false);

    final markers = MapPlaceQuery.markers(
      repository: LocalPlaceRepository(),
      filters: filters,
      favorites: favorites,
    );
    expect(markers, hasLength(1));
    expect(markers.single.placeId, 'place-les-bains-marrakech');
    expect(markers.single.isFavorite, isTrue);
  });
}
