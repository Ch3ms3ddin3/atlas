import '../domain/models/price_models.dart';
import '../domain/price_repository.dart';
import 'local_price_repository.dart';
import 'price_catalog.dart';
import 'price_mapper.dart';
import 'supabase_price_repository.dart';

/// Catalogue éditorial avec repli local si Supabase est indisponible.
class ResilientPriceRepository implements PriceRepository {
  ResilientPriceRepository({
    LocalPriceRepository? local,
    Future<List<PriceGuide>> Function()? fetchRemote,
    Duration? fetchTimeout,
  })  : _local = local ?? LocalPriceRepository(),
        _fetchRemote = fetchRemote ?? const SupabasePriceRepository().fetchAll,
        _fetchTimeout = fetchTimeout ?? const Duration(seconds: 5);

  final LocalPriceRepository _local;
  final Future<List<PriceGuide>> Function() _fetchRemote;
  final Duration _fetchTimeout;

  List<PriceGuide>? _remoteCache;
  bool _warmUpStarted = false;

  List<PriceGuide> get _source => _remoteCache ?? _local.catalog;

  @override
  Future<void> warmUp() async {
    if (_warmUpStarted) return;
    _warmUpStarted = true;

    try {
      final guides = await _fetchRemote().timeout(_fetchTimeout);
      if (guides.isNotEmpty) {
        _remoteCache = List<PriceGuide>.unmodifiable(guides);
      }
    } catch (_) {}
  }

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
    if (_remoteCache == null || _remoteCache!.isEmpty) {
      return PriceCatalog.lastReviewedAt;
    }
    return _remoteCache!
        .map((guide) => guide.lastUpdatedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  List<PriceCategory> get categories => PriceCategory.values;
}
