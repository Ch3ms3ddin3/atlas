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
}
