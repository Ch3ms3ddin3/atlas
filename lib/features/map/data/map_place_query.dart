import '../../explorer/domain/models/place_models.dart';
import '../../explorer/domain/place_browse_filters.dart';
import '../../explorer/domain/place_repository.dart';
import '../../favorites/domain/favorite_entity_type.dart';
import '../../favorites/domain/favorites_repository.dart';
import '../domain/atlas_map_models.dart';

/// Projection filtres partagés → lieux cartographiables (coords obligatoires).
abstract final class MapPlaceQuery {
  static List<PlaceGuide> filteredPlaces({
    required PlaceRepository repository,
    required PlaceBrowseFilters filters,
    FavoritesRepository? favorites,
  }) {
    final results = repository.search(
      PlaceSearchQuery(
        text: filters.searchText,
        category: filters.category,
        cityName: filters.cityName.isEmpty ? null : filters.cityName,
        sort: PlaceSort.catalog,
        strictCity: true,
      ),
    );

    return results.where((place) {
      if (!place.hasCoordinates) return false;
      if (!filters.favoritesOnly) return true;
      if (favorites == null || !favorites.isLoaded) return false;
      return favorites.isFavorite(
        entityType: FavoriteEntityType.place,
        entitySlug: place.id,
      );
    }).toList();
  }

  static List<AtlasMapMarker> markers({
    required PlaceRepository repository,
    required PlaceBrowseFilters filters,
    FavoritesRepository? favorites,
  }) {
    final places = filteredPlaces(
      repository: repository,
      filters: filters,
      favorites: favorites,
    );
    final markers = <AtlasMapMarker>[];
    for (final place in places) {
      final isFavorite = favorites?.isFavorite(
            entityType: FavoriteEntityType.place,
            entitySlug: place.id,
          ) ??
          false;
      final marker = AtlasMapMarker.fromPlace(place, isFavorite: isFavorite);
      if (marker != null) markers.add(marker);
    }
    return markers;
  }
}
