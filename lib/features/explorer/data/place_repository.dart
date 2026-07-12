import '../domain/models/place_models.dart';
import 'place_catalog.dart';
import 'place_mapper.dart';

/// Accès au catalogue local des lieux utiles.
class PlaceRepository {
  const PlaceRepository();

  List<PlaceGuide> getAll({String? cityName}) {
    return PlaceMapper.filter(PlaceSearchQuery(cityName: cityName));
  }

  List<PlaceGuide> getFeatured({String? cityName, int limit = 2}) {
    final places = getAll(cityName: cityName)
        .where((place) => place.isEditorsPick)
        .toList();

    if (places.length >= limit) {
      return places.take(limit).toList();
    }

    final fallback = getAll(cityName: cityName);
    return fallback.take(limit).toList();
  }

  PlaceGuide? findById(String id) {
    return PlaceMapper.findById(id);
  }

  List<PlaceGuide> search(PlaceSearchQuery query) {
    return PlaceMapper.filter(query);
  }

  String resolveCityName(String? cityName) {
    return PlaceMapper.resolveCityName(cityName);
  }

  bool isCityCovered(String? cityName) {
    if (cityName == null || cityName.trim().isEmpty) return true;
    final normalized = cityName.trim().toLowerCase();
    return PlaceCatalog.guides.any(
      (guide) => guide.cityName.toLowerCase() == normalized,
    );
  }

  List<PlaceCategory> get categories => PlaceCategory.values;
}
