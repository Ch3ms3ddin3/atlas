import '../domain/models/price_models.dart';
import 'price_catalog.dart';
import 'price_mapper.dart';

/// Accès au catalogue local des prix moyens.
class PriceRepository {
  const PriceRepository();

  List<PriceGuide> getAll({String? cityName}) {
    return PriceMapper.filter(PriceSearchQuery(cityName: cityName));
  }

  PriceGuide? findById(String id) {
    return PriceMapper.findById(id);
  }

  List<PriceGuide> search(PriceSearchQuery query) {
    return PriceMapper.filter(query);
  }

  String resolveCityName(String? cityName) {
    return PriceMapper.resolveCityName(cityName);
  }

  bool isCityCovered(String? cityName) {
    if (cityName == null || cityName.trim().isEmpty) return true;
    final normalized = cityName.trim().toLowerCase();
    return PriceCatalog.guides.any(
      (guide) =>
          !guide.isNational && guide.cityName.toLowerCase() == normalized,
    );
  }

  /// Date de la dernière révision éditoriale du catalogue.
  DateTime get catalogLastReviewedAt => PriceCatalog.lastReviewedAt;

  List<PriceCategory> get categories => PriceCategory.values;
}
