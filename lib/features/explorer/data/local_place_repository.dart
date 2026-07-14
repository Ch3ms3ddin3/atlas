import '../domain/models/place_models.dart';
import '../domain/place_repository.dart';
import 'place_catalog.dart';
import 'place_mapper.dart';

/// Catalogue statique local — repli permanent et hors-ligne.
class LocalPlaceRepository implements PlaceRepository {
  LocalPlaceRepository();

  List<PlaceGuide> get catalog =>
      List<PlaceGuide>.unmodifiable(PlaceCatalog.guides);

  @override
  Future<void> warmUp() async {}

  @override
  List<PlaceGuide> getAll({String? cityName}) {
    return PlaceMapper.filter(PlaceSearchQuery(cityName: cityName));
  }

  @override
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

  @override
  PlaceGuide? findById(String id) {
    return PlaceMapper.findById(id);
  }

  @override
  List<PlaceGuide> search(PlaceSearchQuery query) {
    return PlaceMapper.filter(query);
  }

  @override
  String resolveCityName(String? cityName) {
    return PlaceMapper.resolveCityName(cityName);
  }

  @override
  bool isCityCovered(String? cityName) {
    if (cityName == null || cityName.trim().isEmpty) return true;
    final normalized = cityName.trim().toLowerCase();
    return PlaceCatalog.guides.any(
      (guide) => guide.cityName.toLowerCase() == normalized,
    );
  }

  @override
  List<PlaceCategory> get categories => PlaceCategory.values;
}
