import 'package:flutter/foundation.dart';

import '../../../core/editorial/editorial_catalog_load_state.dart';
import '../domain/models/price_observation.dart';
import '../domain/price_intelligence_repository.dart';
import 'price_intelligence_cache_store.dart';
import 'price_observation_query.dart';
import 'supabase_price_intelligence_repository.dart';

/// Price Intelligence : seed bundlé → cache disque → Supabase vérifié.
///
/// Ordre :
/// 1. Cache local s'il existe (dernière sync distante réussie), fusionné au seed.
/// 2. Sinon seed catalogue vérifié (bootstrap / premier lancement offline).
/// 3. Remote non vide : fusion par slug (distant prioritaire, seed-only conservé).
/// 4. Remote vide : liste vide (aucune invention côté client).
///
/// Le seed n'est jamais poussé vers Supabase. Le cache disque stocke le résultat
/// fusionné après un fetch distant non vide.
class ResilientPriceIntelligenceRepository
    with ChangeNotifier
    implements PriceIntelligenceRepository {
  ResilientPriceIntelligenceRepository({
    PriceIntelligenceCacheStore? cacheStore,
    Future<List<PriceObservation>> Function()? fetchRemote,
    Duration? fetchTimeout,
    List<PriceObservation>? seedItems,
  }) : _cacheStore = cacheStore ?? const PriceIntelligenceCacheStore(),
       _fetchRemote =
           fetchRemote ?? const SupabasePriceIntelligenceRepository().fetchAll,
       _fetchTimeout = fetchTimeout ?? const Duration(seconds: 5),
       _seedItems = List<PriceObservation>.unmodifiable(seedItems ?? const []),
       _items = List<PriceObservation>.unmodifiable(seedItems ?? const []);

  final PriceIntelligenceCacheStore _cacheStore;
  final Future<List<PriceObservation>> Function() _fetchRemote;
  final Duration _fetchTimeout;
  final List<PriceObservation> _seedItems;

  List<PriceObservation> _items;
  EditorialCatalogLoadState _loadState = EditorialCatalogLoadState.idle;
  Object? _lastError;
  bool _warmUpStarted = false;
  bool _usingCacheOnly = false;

  EditorialCatalogLoadState get loadState => _loadState;
  Object? get lastError => _lastError;
  bool get isUsingCacheOnly => _usingCacheOnly;

  /// Fusionne [remote] sur [seed] par `PriceObservation.id` (slug).
  ///
  /// - distant vide → liste vide (pas d'invention) ;
  /// - même id → version distante ;
  /// - id seed seul → conservé (ex. Wave 2 avant migration remote) ;
  /// - id distant seul → ajouté.
  @visibleForTesting
  static List<PriceObservation> mergeRemoteOverSeed({
    required List<PriceObservation> seed,
    required List<PriceObservation> remote,
  }) {
    if (remote.isEmpty) return remote;

    final remoteById = <String, PriceObservation>{
      for (final item in remote) item.id: item,
    };
    final seen = <String>{};
    final merged = <PriceObservation>[];

    for (final seedItem in seed) {
      merged.add(remoteById[seedItem.id] ?? seedItem);
      seen.add(seedItem.id);
    }
    for (final remoteItem in remote) {
      if (seen.add(remoteItem.id)) {
        merged.add(remoteItem);
      }
    }
    return merged;
  }

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
      _setItems(mergeRemoteOverSeed(seed: _seedItems, remote: cached));
      _usingCacheOnly = true;
      _setLoadState(EditorialCatalogLoadState.stale);
      notifyListeners();
    } else if (_seedItems.isNotEmpty) {
      // Premier lancement / cache vide : peindre le catalogue vérifié bundlé
      // avant le round-trip réseau (ou en secours hors ligne).
      _setItems(_seedItems);
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
      final merged = mergeRemoteOverSeed(seed: _seedItems, remote: remote);
      _setItems(merged);
      _usingCacheOnly = false;
      if (remote.isNotEmpty) {
        await _cacheStore.save(merged);
      }
      _setLoadState(EditorialCatalogLoadState.success);
      notifyListeners();
    } catch (error) {
      _lastError = error;
      if (_items.isEmpty && _seedItems.isNotEmpty) {
        // Secours ultime si un refresh a vidé la mémoire sans cache.
        _setItems(_seedItems);
      }
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
    // Ne pas exposer le sentinel national comme puce de ville.
    final cities =
        _items
            .where((e) => !e.isNational)
            .map((e) => e.cityName)
            .toSet()
            .toList()
          ..sort();
    return cities;
  }

  @override
  List<PriceIntelligenceCategory> get categories {
    final present = _items.map((e) => e.category).toSet().toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return present;
  }
}
