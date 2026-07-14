import '../domain/models/price_models.dart';
import '../domain/price_repository.dart';
import 'price_catalog.dart';
import 'price_mapper.dart';

/// Catalogue statique local — repli permanent et hors-ligne.
class LocalPriceRepository implements PriceRepository {
  LocalPriceRepository();

  List<PriceGuide> get catalog =>
      List<PriceGuide>.unmodifiable(PriceCatalog.guides);

  @override
  Future<void> warmUp() async {}

  @override
  List<PriceGuide> getAll({String? cityName}) {
    return PriceMapper.filter(PriceSearchQuery(cityName: cityName));
  }

  @override
  PriceGuide? findById(String id) {
    return PriceMapper.findById(id);
  }

  @override
  List<PriceGuide> search(PriceSearchQuery query) {
    return PriceMapper.filter(query);
  }

  @override
  String resolveCityName(String? cityName) {
    return PriceMapper.resolveCityName(cityName);
  }

  @override
  bool isCityCovered(String? cityName) {
    if (cityName == null || cityName.trim().isEmpty) return true;
    final normalized = cityName.trim().toLowerCase();
    return PriceCatalog.guides.any(
      (guide) =>
          !guide.isNational && guide.cityName.toLowerCase() == normalized,
    );
  }

  @override
  DateTime get catalogLastReviewedAt => PriceCatalog.lastReviewedAt;

  @override
  List<PriceCategory> get categories => PriceCategory.values;
}
