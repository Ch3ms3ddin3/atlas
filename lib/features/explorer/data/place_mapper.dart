import '../../../core/location/location_constants.dart';
import '../../home/domain/models/home_models.dart';
import '../domain/models/place_models.dart';
import 'place_catalog.dart';

/// Filtre le catalogue et convertit vers les modèles d'affichage.
abstract final class PlaceMapper {
  static const categoryLabels = {
    PlaceCategory.jardin: 'Jardin',
    PlaceCategory.monument: 'Monument',
    PlaceCategory.restaurant: 'Restaurant',
    PlaceCategory.cafe: 'Café',
    PlaceCategory.musee: 'Musée',
    PlaceCategory.hammam: 'Hammam',
    PlaceCategory.plage: 'Plage',
    PlaceCategory.souk: 'Souk',
  };

  static const sortLabels = {
    PlaceSort.catalog: 'Ordre Atlas',
    PlaceSort.nameAsc: 'Nom A–Z',
    PlaceSort.neighborhood: 'Quartier',
    PlaceSort.priceLevel: 'Prix',
    PlaceSort.editorsPick: 'Sélection',
  };

  static String resolveCityName(
    String? cityName, {
    Iterable<PlaceGuide>? guides,
  }) {
    if (cityName == null || cityName.trim().isEmpty) {
      return LocationConstants.fallbackCity;
    }

    final normalized = cityName.trim().toLowerCase();
    final catalog = guides ?? PlaceCatalog.guides;
    final knownCities = catalog
        .map((guide) => guide.cityName.toLowerCase())
        .toSet();

    if (knownCities.contains(normalized)) {
      return _canonicalCityName(normalized, catalog);
    }

    return LocationConstants.fallbackCity;
  }

  /// Filtre puis trie selon [PlaceSearchQuery.sort].
  static List<PlaceGuide> filter(
    PlaceSearchQuery query, {
    List<PlaceGuide>? source,
  }) {
    final catalog = source ?? PlaceCatalog.guides;
    final cityName = _effectiveCityName(query, catalog);
    final normalizedQuery = query.text.trim().toLowerCase();

    final filtered = catalog.where((guide) {
      if (guide.cityName.toLowerCase() != cityName.toLowerCase()) {
        return false;
      }
      if (query.category != null && guide.category != query.category) {
        return false;
      }
      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        guide.name,
        guide.summary,
        guide.neighborhood,
        guide.categoryLabel,
      ].join(' ').toLowerCase();

      return haystack.contains(normalizedQuery);
    }).toList();

    return sortPlaces(filtered, query.sort);
  }

  /// Trie une liste déjà filtrée sans modifier l'ordre source si [sort] est catalog.
  static List<PlaceGuide> sortPlaces(List<PlaceGuide> places, PlaceSort sort) {
    if (sort == PlaceSort.catalog || places.length < 2) {
      return places;
    }

    final sorted = List<PlaceGuide>.from(places);
    switch (sort) {
      case PlaceSort.catalog:
        break;
      case PlaceSort.nameAsc:
        sorted.sort((a, b) => a.name.compareTo(b.name));
      case PlaceSort.neighborhood:
        sorted.sort((a, b) {
          final byNeighborhood = a.neighborhood.compareTo(b.neighborhood);
          if (byNeighborhood != 0) return byNeighborhood;
          return a.name.compareTo(b.name);
        });
      case PlaceSort.priceLevel:
        sorted.sort((a, b) {
          final byPrice =
              _priceLevelRank(a.priceLevel).compareTo(_priceLevelRank(b.priceLevel));
          if (byPrice != 0) return byPrice;
          return a.name.compareTo(b.name);
        });
      case PlaceSort.editorsPick:
        sorted.sort((a, b) {
          if (a.isEditorsPick != b.isEditorsPick) {
            return a.isEditorsPick ? -1 : 1;
          }
          return a.name.compareTo(b.name);
        });
    }
    return sorted;
  }

  static PlaceGuide? findById(
    String id, {
    List<PlaceGuide>? source,
  }) {
    final catalog = source ?? PlaceCatalog.guides;
    for (final guide in catalog) {
      if (guide.id == id) return guide;
    }
    return null;
  }

  static RecommendedPlaceData toRecommendedPlaceData(PlaceGuide guide) {
    return RecommendedPlaceData(
      id: guide.id,
      name: guide.name,
      category: guide.categoryLabel,
      distanceLabel: guide.neighborhood,
      priceLevel: guide.priceLevel,
      isEditorsPick: guide.isEditorsPick,
      imageColor: guide.imageColor,
    );
  }

  static String _effectiveCityName(
    PlaceSearchQuery query,
    Iterable<PlaceGuide> catalog,
  ) {
    if (!query.strictCity) {
      return resolveCityName(query.cityName, guides: catalog);
    }
    if (query.cityName == null || query.cityName!.trim().isEmpty) {
      return LocationConstants.fallbackCity;
    }
    return query.cityName!.trim();
  }

  static int _priceLevelRank(String priceLevel) {
    final normalized = priceLevel.trim().toLowerCase();
    if (normalized.contains('gratuit')) return 0;
    final euroCount = '€'.allMatches(priceLevel).length;
    if (euroCount > 0) return euroCount;
    return 99;
  }

  static String _canonicalCityName(
    String normalizedCity,
    Iterable<PlaceGuide> guides,
  ) {
    for (final guide in guides) {
      if (guide.cityName.toLowerCase() == normalizedCity) {
        return guide.cityName;
      }
    }
    return LocationConstants.fallbackCity;
  }
}
