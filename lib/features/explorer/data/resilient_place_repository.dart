import 'package:flutter/foundation.dart';

import '../../../core/editorial/editorial_catalog_load_state.dart';
import '../../../core/editorial/resilient_editorial_catalog.dart';
import '../domain/models/place_models.dart';
import '../domain/place_repository.dart';
import 'local_place_repository.dart';
import 'place_mapper.dart';
import 'supabase_place_repository.dart';

/// Lieux : local immédiat, puis refresh Supabase via [ResilientEditorialCatalog].
///
/// Les slugs (`PlaceGuide.id`) restent stables pour favoris et signalements.
/// Un distant non vide est fusionné au local par `id` (distant prioritaire),
/// sans jamais effacer les lieux locaux absents du remote.
class ResilientPlaceRepository with ChangeNotifier implements PlaceRepository {
  ResilientPlaceRepository({
    LocalPlaceRepository? local,
    Future<List<PlaceGuide>> Function()? fetchRemote,
    Duration? fetchTimeout,
  }) : this._fromItems(
         localItems: List<PlaceGuide>.unmodifiable(
           (local ?? LocalPlaceRepository()).items,
         ),
         fetchRemote: fetchRemote ?? const SupabasePlaceRepository().fetchAll,
         fetchTimeout: fetchTimeout ?? const Duration(seconds: 15),
       );

  ResilientPlaceRepository._fromItems({
    required List<PlaceGuide> localItems,
    required Future<List<PlaceGuide>> Function() fetchRemote,
    required Duration fetchTimeout,
  }) : _catalog = ResilientEditorialCatalog<PlaceGuide>(
         localItems: localItems,
         fetchRemote: () async {
           final remote = await fetchRemote();
           return mergeRemoteOverLocal(local: localItems, remote: remote);
         },
         fetchTimeout: fetchTimeout,
       ) {
    _catalog.addListener(_onCatalogChanged);
  }

  final ResilientEditorialCatalog<PlaceGuide> _catalog;

  /// Fusionne [remote] sur [local] par `PlaceGuide.id`.
  ///
  /// - distant vide → liste vide (le catalogue reste en repli local) ;
  /// - même id → version distante ;
  /// - id local seul → conservé ;
  /// - id distant seul → ajouté ;
  /// - aucun doublon.
  @visibleForTesting
  static List<PlaceGuide> mergeRemoteOverLocal({
    required List<PlaceGuide> local,
    required List<PlaceGuide> remote,
  }) {
    if (remote.isEmpty) return remote;

    final remoteById = <String, PlaceGuide>{
      for (final place in remote) place.id: place,
    };
    final seen = <String>{};
    final merged = <PlaceGuide>[];

    for (final localPlace in local) {
      merged.add(remoteById[localPlace.id] ?? localPlace);
      seen.add(localPlace.id);
    }
    for (final remotePlace in remote) {
      if (seen.add(remotePlace.id)) {
        merged.add(remotePlace);
      }
    }
    return merged;
  }

  /// État exposé par l'abstraction éditoriale partagée.
  EditorialCatalogLoadState get loadState => _catalog.loadState;

  /// Dernière erreur distante, si [loadState] est [EditorialCatalogLoadState.error].
  Object? get lastError => _catalog.lastError;

  /// `true` lorsque le cache distant (fusionné) est actif.
  bool get isUsingRemote => _catalog.isUsingRemote;

  List<PlaceGuide> get _source => _catalog.items;

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
  List<PlaceGuide> getAll({String? cityName}) {
    return PlaceMapper.filter(
      PlaceSearchQuery(cityName: cityName),
      source: _source,
    );
  }

  @override
  List<PlaceGuide> getFeatured({String? cityName, int limit = 2}) {
    final places = getAll(
      cityName: cityName,
    ).where((place) => place.isEditorsPick).toList();

    if (places.length >= limit) {
      return places.take(limit).toList();
    }

    return getAll(cityName: cityName).take(limit).toList();
  }

  @override
  PlaceGuide? findById(String id) {
    return PlaceMapper.findById(id, source: _source);
  }

  @override
  List<PlaceGuide> search(PlaceSearchQuery query) {
    return PlaceMapper.filter(query, source: _source);
  }

  @override
  String resolveCityName(String? cityName) {
    return PlaceMapper.resolveCityName(cityName, guides: _source);
  }

  @override
  bool isCityCovered(String? cityName) {
    if (cityName == null || cityName.trim().isEmpty) return true;
    final normalized = cityName.trim().toLowerCase();
    return _source.any((guide) => guide.cityName.toLowerCase() == normalized);
  }

  @override
  List<PlaceCategory> get categories =>
      PlaceMapper.categoriesPresentIn(_source);
}
