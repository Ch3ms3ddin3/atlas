import 'package:flutter/foundation.dart';

import '../../../core/editorial/editorial_catalog_load_state.dart';
import '../../../core/editorial/resilient_editorial_catalog.dart';
import '../domain/models/price_models.dart';
import '../domain/price_repository.dart';
import 'local_price_repository.dart';
import 'price_catalog.dart';
import 'price_mapper.dart';
import 'supabase_price_repository.dart';

/// Prix : local immédiat, puis refresh Supabase via [ResilientEditorialCatalog].
///
/// Les slugs (`PriceGuide.id`) restent stables pour favoris et signalements.
class ResilientPriceRepository with ChangeNotifier implements PriceRepository {
  ResilientPriceRepository({
    LocalPriceRepository? local,
    Future<List<PriceGuide>> Function()? fetchRemote,
    Duration? fetchTimeout,
  }) : _catalog = ResilientEditorialCatalog<PriceGuide>(
          localItems: (local ?? LocalPriceRepository()).items,
          fetchRemote: fetchRemote ?? const SupabasePriceRepository().fetchAll,
          fetchTimeout: fetchTimeout,
        ) {
    _catalog.addListener(_onCatalogChanged);
  }

  final ResilientEditorialCatalog<PriceGuide> _catalog;

  /// État exposé par l'abstraction éditoriale partagée.
  EditorialCatalogLoadState get loadState => _catalog.loadState;

  /// Dernière erreur distante, si [loadState] est [EditorialCatalogLoadState.error].
  Object? get lastError => _catalog.lastError;

  /// `true` lorsque les données affichées viennent de Supabase.
  bool get isUsingRemote => _catalog.isUsingRemote;

  List<PriceGuide> get _source => _catalog.items;

  void _onCatalogChanged() => notifyListeners();

  @override
  void dispose() {
    _catalog.removeListener(_onCatalogChanged);
    _catalog.dispose();
    super.dispose();
  }

  @override
  Future<void> warmUp() => _catalog.warmUp();

  @override
  List<PriceGuide> getAll({String? cityName}) {
    return PriceMapper.filter(
      PriceSearchQuery(cityName: cityName),
      source: _source,
    );
  }

  @override
  PriceGuide? findById(String id) {
    return PriceMapper.findById(id, source: _source);
  }

  @override
  List<PriceGuide> search(PriceSearchQuery query) {
    return PriceMapper.filter(query, source: _source);
  }

  @override
  String resolveCityName(String? cityName) {
    return PriceMapper.resolveCityName(cityName, guides: _source);
  }

  @override
  bool isCityCovered(String? cityName) {
    if (cityName == null || cityName.trim().isEmpty) return true;
    final normalized = cityName.trim().toLowerCase();
    return _source.any(
      (guide) =>
          !guide.isNational && guide.cityName.toLowerCase() == normalized,
    );
  }

  @override
  DateTime get catalogLastReviewedAt {
    if (!isUsingRemote) {
      return PriceCatalog.lastReviewedAt;
    }
    return _source
        .map((guide) => guide.lastUpdatedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  List<PriceCategory> get categories => PriceCategory.values;
}
