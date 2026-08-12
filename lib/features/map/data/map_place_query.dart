import '../../explorer/domain/models/place_models.dart';
import '../../explorer/domain/place_browse_filters.dart';
import '../../explorer/domain/place_repository.dart';
import '../../favorites/domain/favorite_entity_type.dart';
import '../../favorites/domain/favorites_repository.dart';
import '../domain/atlas_map_models.dart';
import 'map_search_text.dart';

/// Projection filtres partagés → lieux cartographiables (coords obligatoires).
abstract final class MapPlaceQuery {
  static List<PlaceGuide> filteredPlaces({
    required PlaceRepository repository,
    required PlaceBrowseFilters filters,
    FavoritesRepository? favorites,
  }) {
    // City/category via le dépôt partagé ; texte géré ici (accents ignorés).
    final results = repository.search(
      PlaceSearchQuery(
        text: '',
        category: filters.category,
        cityName: filters.cityName.isEmpty ? null : filters.cityName,
        sort: PlaceSort.catalog,
        strictCity: true,
      ),
    );

    final needle = MapSearchText.normalize(filters.searchText);
    final matched = results.where((place) {
      if (!place.hasCoordinates) return false;

      if (needle.isNotEmpty &&
          !MapSearchText.placeMatches(
            query: needle,
            name: place.name,
            summary: place.summary,
            neighborhood: place.neighborhood,
            categoryLabel: place.categoryLabel,
            categoryEnumName: place.category.name,
            placeId: place.id,
          )) {
        return false;
      }

      if (!filters.favoritesOnly) return true;
      if (favorites == null || !favorites.isLoaded) return false;
      return favorites.isFavorite(
        entityType: FavoriteEntityType.place,
        entitySlug: place.id,
      );
    }).toList();

    if (needle.isEmpty || matched.length < 2) return matched;

    // Même pertinence nom-first que Explorer (PlaceMapper.filter).
    final indexed = [
      for (var i = 0; i < matched.length; i++) (index: i, place: matched[i]),
    ];
    indexed.sort((a, b) {
      final rankA = MapSearchText.relevanceRank(
        query: needle,
        name: a.place.name,
        summary: a.place.summary,
        neighborhood: a.place.neighborhood,
        categoryLabel: a.place.categoryLabel,
        placeId: a.place.id,
      );
      final rankB = MapSearchText.relevanceRank(
        query: needle,
        name: b.place.name,
        summary: b.place.summary,
        neighborhood: b.place.neighborhood,
        categoryLabel: b.place.categoryLabel,
        placeId: b.place.id,
      );
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.index.compareTo(b.index);
    });
    return [for (final entry in indexed) entry.place];
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
      final isFavorite =
          favorites?.isFavorite(
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
