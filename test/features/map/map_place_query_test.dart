import 'package:atlas/features/explorer/data/local_place_repository.dart';
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

  test('exclut les lieux sans coordonnées', () {
    final filters = PlaceBrowseFilters.instance;
    filters.setCityName('Marrakech', notify: false);
    final markers = MapPlaceQuery.markers(
      repository: LocalPlaceRepository(),
      filters: filters,
    );
    expect(markers, isNotEmpty);
    expect(markers.every((m) => m.placeId != 'place-hammam-marrakech'), isTrue);
    expect(markers.any((m) => m.placeId == 'place-majorelle'), isTrue);
    expect(markers.any((m) => m.placeId == 'place-les-bains-marrakech'), isTrue);
  });

  test('filtre favoris uniquement', () async {
    final favorites = LocalFavoritesRepository();
    await favorites.load();
    await favorites.addFavorite(
      entityType: FavoriteEntityType.place,
      entitySlug: 'place-majorelle',
    );

    final filters = PlaceBrowseFilters.instance;
    filters.setCityName('Marrakech', notify: false);
    filters.setFavoritesOnly(true, notify: false);

    final markers = MapPlaceQuery.markers(
      repository: LocalPlaceRepository(),
      filters: filters,
      favorites: favorites,
    );
    expect(markers, hasLength(1));
    expect(markers.single.placeId, 'place-majorelle');
    expect(markers.single.isFavorite, isTrue);
  });

  test('filtre catégorie partagée', () {
    final filters = PlaceBrowseFilters.instance;
    filters.setCityName('Marrakech', notify: false);
    filters.setCategory(PlaceCategory.jardin, notify: false);
    final markers = MapPlaceQuery.markers(
      repository: LocalPlaceRepository(),
      filters: filters,
    );
    expect(markers.every((m) => m.category == PlaceCategory.jardin), isTrue);
  });

  test('recherche Carte ignore accents et casse (musée / musee)', () {
    final repo = LocalPlaceRepository();
    final filters = PlaceBrowseFilters.instance;
    filters.setCityName('Marrakech', notify: false);

    List<String> idsFor(String query) {
      filters.setSearchText(query, notify: false);
      return MapPlaceQuery.markers(repository: repo, filters: filters)
          .map((m) => m.placeId)
          .toList()
        ..sort();
    }

    final accented = idsFor('musée');
    final plain = idsFor('musee');
    final upper = idsFor('MUSEE');
    final mixed = idsFor('Musée');
    final title = idsFor('Musee');

    expect(accented, isNotEmpty);
    expect(accented, contains('place-ysl-museum'));
    expect(plain, accented);
    expect(upper, accented);
    expect(mixed, accented);
    expect(title, accented);
  });

  test('recherche Carte médina / medina et guéliz si présent', () {
    final repo = LocalPlaceRepository();
    final filters = PlaceBrowseFilters.instance;
    filters.setCityName('Marrakech', notify: false);

    List<String> idsFor(String query) {
      filters.setSearchText(query, notify: false);
      return MapPlaceQuery.markers(repository: repo, filters: filters)
          .map((m) => m.placeId)
          .toList()
        ..sort();
    }

    expect(idsFor('medina'), idsFor('médina'));
    expect(idsFor('MEDINA'), idsFor('Médina'));
    expect(idsFor('medina'), isNotEmpty);
  });
}

