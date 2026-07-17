import 'package:flutter/foundation.dart';

import '../../../core/editorial/editorial_catalog_load_state.dart';
import '../domain/models/price_observation.dart';
import '../domain/price_intelligence_repository.dart';
import 'price_intelligence_cache_store.dart';
import 'price_observation_query.dart';
import 'supabase_price_intelligence_repository.dart';

/// Price Intelligence : Supabase vérifié + cache disque. Aucun catalogue inventé.
class ResilientPriceIntelligenceRepository
    with ChangeNotifier
    implements PriceIntelligenceRepository {
  ResilientPriceIntelligenceRepository({
    PriceIntelligenceCacheStore? cacheStore,
    Future<List<PriceObservation>> Function()? fetchRemote,
    Duration? fetchTimeout,
    List<PriceObservation>? seedItems,
  })  : _cacheStore = cacheStore ?? const PriceIntelligenceCacheStore(),
        _fetchRemote =
            fetchRemote ?? const SupabasePriceIntelligenceRepository().fetchAll,
        _fetchTimeout = fetchTimeout ?? const Duration(seconds: 5),
        _items = List<PriceObservation>.unmodifiable(seedItems ?? const []);

  final PriceIntelligenceCacheStore _cacheStore;
  final Future<List<PriceObservation>> Function() _fetchRemote;
  final Duration _fetchTimeout;

  List<PriceObservation> _items;
  EditorialCatalogLoadState _loadState = EditorialCatalogLoadState.idle;
  Object? _lastError;
  bool _warmUpStarted = false;
  bool _usingCacheOnly = false;

  EditorialCatalogLoadState get loadState => _loadState;
  Object? get lastError => _lastError;
  bool get isUsingCacheOnly => _usingCacheOnly;

  void _setItems(List<PriceObservation> next) {
    _items = List<PriceObservation>.unmodifiable(next);
  }

  void _setLoadState(EditorialCatalogLoadState next) {
    if (_loadState == next) return;
    _loadState = next;
    notifyListeners();
  }

  @override
  Future<void> warmUp() async {
    if (_warmUpStarted) return;
    _warmUpStarted = true;

    final cached = await _cacheStore.load();
    if (cached.isNotEmpty) {
      _setItems(cached);
      _usingCacheOnly = true;
      _setLoadState(EditorialCatalogLoadState.stale);
      notifyListeners();
    } else {
      _setLoadState(EditorialCatalogLoadState.loading);
    }

    await refresh();
  }

  @override
  Future<void> refresh() async {
    _lastError = null;
    if (_items.isEmpty) {
      _setLoadState(EditorialCatalogLoadState.loading);
    }

    try {
      final remote = await _fetchRemote().timeout(_fetchTimeout);
      _setItems(remote);
      _usingCacheOnly = false;
      if (remote.isNotEmpty) {
        await _cacheStore.save(remote);
      }
      _setLoadState(EditorialCatalogLoadState.success);
      notifyListeners();
    } catch (error) {
      _lastError = error;
      if (_items.isEmpty) {
        _usingCacheOnly = false;
        _setLoadState(EditorialCatalogLoadState.error);
      } else {
        _usingCacheOnly = true;
        _setLoadState(EditorialCatalogLoadState.stale);
      }
      notifyListeners();
    }
  }

  @override
  List<PriceObservation> getAll({String? cityName}) {
    return PriceObservationQuery.filter(
      PriceIntelligenceQuery(cityName: cityName),
      source: _items,
    );
  }

  @override
  PriceObservation? findById(String id) {
    return PriceObservationQuery.findById(id, source: _items);
  }

  @override
  List<PriceObservation> search(PriceIntelligenceQuery query) {
    return PriceObservationQuery.filter(query, source: _items);
  }

  @override
  List<PriceObservation> highlights({String? cityName, int limit = 5}) {
    return PriceObservationQuery.highlights(
      source: _items,
      cityName: cityName,
      limit: limit,
    );
  }

  @override
  List<String> get availableCities {
    final cities = _items.map((e) => e.cityName).toSet().toList()..sort();
    return cities;
  }

  @override
  List<PriceIntelligenceCategory> get categories =>
      PriceIntelligenceCategory.values;
}
