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

  static List<PlaceGuide> filter(
    PlaceSearchQuery query, {
    List<PlaceGuide>? source,
  }) {
    final catalog = source ?? PlaceCatalog.guides;
    final cityName = resolveCityName(query.cityName, guides: catalog);
    final normalizedQuery = query.text.trim().toLowerCase();

    return catalog.where((guide) {
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
