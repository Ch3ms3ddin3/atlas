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

  const expectedRestaurants =
      <String, ({double lat, double lng, bool selection})>{
        'place-al-fassia-gueliz': (
          lat: 31.635992,
          lng: -8.013364,
          selection: true,
        ),
        'place-amal-gueliz': (lat: 31.639072, lng: -8.013756, selection: true),
        'place-nomad': (lat: 31.628593, lng: -7.987530, selection: true),
        'place-plus61': (lat: 31.635162, lng: -8.015502, selection: false),
        'place-le-jardin': (lat: 31.632074, lng: -7.988806, selection: false),
        'place-sahbi-sahbi': (lat: 31.634075, lng: -8.014582, selection: false),
        'place-grand-cafe-de-la-poste': (
          lat: 31.633120,
          lng: -8.010006,
          selection: false,
        ),
        'place-catanzaro': (lat: 31.634900, lng: -8.010477, selection: false),
        'place-naranj': (lat: 31.624537, lng: -7.985213, selection: false),
        'place-la-trattoria': (
          lat: 31.633840,
          lng: -8.015174,
          selection: false,
        ),
        'place-dar-moha': (lat: 31.631367, lng: -7.993267, selection: false),
      };

  const expectedHammams = <String>{
    'place-les-bains-marrakech',
    'place-hammam-de-la-rose',
    'place-heritage-spa',
    'place-hammam-place-des-epices',
  };

  const expectedCafes = <String>{
    'place-bacha-coffee',
    'place-simple-specialty-coffee',
    'place-cafe-des-epices',
    'place-kartell-kollektiv',
    'place-cafe-clock',
  };

  test('eleven verified Marrakech restaurants exist with unique IDs', () {
    final ids = PlaceCatalog.guides.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final id in expectedRestaurants.keys) {
      expect(ids, contains(id));
    }
    expect(
      PlaceCatalog.guides.where(
        (p) =>
            p.cityName == 'Marrakech' && p.category == PlaceCategory.restaurant,
      ),
      hasLength(11),
    );
  });

  test('exact verified coordinates and Al Fassia / Amal / Nomad Selection', () {
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
      if (entry.key == 'place-amal-gueliz') {
        expect(place.hasPrimaryImage, isTrue);
        expect(
          place.primaryImageUrl,
          contains('place-photos/place-amal-gueliz/cover.webp'),
        );
      } else {
        expect(place.imageUrls, isEmpty);
      }
      expect(place.latitude!.isFinite, isTrue);
      expect(place.longitude!.isFinite, isTrue);
    }
    expect(
      PlaceCatalog.guides.where(
        (p) =>
            p.isEditorsPick &&
            p.cityName == 'Marrakech' &&
            p.category == PlaceCategory.restaurant,
      ),
      hasLength(3),
    );
    expect(
      PlaceCatalog.guides
          .firstWhere((p) => p.id == 'place-al-fassia-gueliz')
          .isEditorsPick,
      isTrue,
    );
    expect(
      PlaceCatalog.guides
          .firstWhere((p) => p.id == 'place-sahbi-sahbi')
          .isEditorsPick,
      isFalse,
    );
  });

  test('branch identity guards (Guéliz / Le Jardin / Italian lanes)', () {
    final fassia = PlaceCatalog.guides.firstWhere(
      (p) => p.id == 'place-al-fassia-gueliz',
    );
    expect(fassia.name, 'Al Fassia Guéliz');
    expect(fassia.address!.toLowerCase(), contains('zerktouni'));
    expect(fassia.summary.toLowerCase(), contains('aguedal'));

    final amal = PlaceCatalog.guides.firstWhere(
      (p) => p.id == 'place-amal-gueliz',
    );
    expect(amal.name, 'Restaurant Amal Guéliz');
    expect(
      amal.practicalTips.any((t) => t.toLowerCase().contains('targa')),
      isTrue,
    );

    final jardin = PlaceCatalog.guides.firstWhere(
      (p) => p.id == 'place-le-jardin',
    );
    expect(jardin.name, 'Le Jardin');
    expect(
      jardin.practicalTips.any((t) => t.contains('Les Jardins de la Medina')),
      isTrue,
    );

    final trattoria = PlaceCatalog.guides.firstWhere(
      (p) => p.id == 'place-la-trattoria',
    );
    expect(trattoria.name, 'La Trattoria');
    expect(trattoria.practicalTips.any((t) => t.contains('Catanzaro')), isTrue);

    final catanzaro = PlaceCatalog.guides.firstWhere(
      (p) => p.id == 'place-catanzaro',
    );
    expect(catanzaro.name, 'Catanzaro');
    expect(catanzaro.priceLevel, '€€');
  });

  test('Marrakech + restaurant returns exactly the 11 curated restaurants', () {
    final filters = PlaceBrowseFilters.instance
      ..setCityName('Marrakech', notify: false)
      ..setCategory(PlaceCategory.restaurant, notify: false);
    final markers = MapPlaceQuery.markers(
      repository: LocalPlaceRepository(),
      filters: filters,
    );
    expect(markers, hasLength(11));
    expect(
      markers.every((m) => m.category == PlaceCategory.restaurant),
      isTrue,
    );
    expect(
      markers.map((m) => m.placeId).toSet(),
      expectedRestaurants.keys.toSet(),
    );
    expect(markers.any((m) => m.placeId == 'place-marche-central'), isFalse);
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

  test('cafés and hammams remain intact', () {
    expect(
      PlaceCatalog.guides
          .where(
            (p) =>
                p.cityName == 'Marrakech' && p.category == PlaceCategory.cafe,
          )
          .map((p) => p.id)
          .toSet(),
      expectedCafes,
    );
    for (final id in expectedHammams) {
      final place = PlaceCatalog.guides.firstWhere((p) => p.id == id);
      expect(place.category, PlaceCategory.hammam);
      expect(place.hasCoordinates, isTrue);
    }
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
  });

  test('rejected or deferred restaurants are absent', () {
    expect(PlaceCatalog.guides.any((p) => p.id == 'place-lmida'), isFalse);
    expect(PlaceCatalog.guides.any((p) => p.name == "L'Mida"), isFalse);
    expect(
      PlaceCatalog.guides.any((p) => p.name == 'Les Jardins de la Medina'),
      isFalse,
    );
    expect(PlaceCatalog.guides.any((p) => p.id == 'place-libzar'), isFalse);
    expect(
      PlaceCatalog.guides.any((p) => p.id == 'place-comptoir-darna'),
      isFalse,
    );
  });
}
