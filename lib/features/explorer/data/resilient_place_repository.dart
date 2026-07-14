import '../domain/models/place_models.dart';
import '../domain/place_repository.dart';
import 'local_place_repository.dart';
import 'place_mapper.dart';
import 'supabase_place_repository.dart';

/// Catalogue éditorial avec repli local si Supabase est indisponible.
class ResilientPlaceRepository implements PlaceRepository {
  ResilientPlaceRepository({
    LocalPlaceRepository? local,
    Future<List<PlaceGuide>> Function()? fetchRemote,
    Duration? fetchTimeout,
  })  : _local = local ?? LocalPlaceRepository(),
        _fetchRemote = fetchRemote ?? const SupabasePlaceRepository().fetchAll,
        _fetchTimeout = fetchTimeout ?? const Duration(seconds: 5);

  final LocalPlaceRepository _local;
  final Future<List<PlaceGuide>> Function() _fetchRemote;
  final Duration _fetchTimeout;

  List<PlaceGuide>? _remoteCache;
  bool _warmUpStarted = false;

  List<PlaceGuide> get _source => _remoteCache ?? _local.catalog;

  @override
  Future<void> warmUp() async {
    if (_warmUpStarted) return;
    _warmUpStarted = true;

    try {
      final guides = await _fetchRemote().timeout(_fetchTimeout);
      if (guides.isNotEmpty) {
        _remoteCache = List<PlaceGuide>.unmodifiable(guides);
      }
    } catch (_) {}
  }

  @override
  List<PlaceGuide> getAll({String? cityName}) {
    return PlaceMapper.filter(
      PlaceSearchQuery(cityName: cityName),
      source: _source,
    );
  }

  @override
  List<PlaceGuide> getFeatured({String? cityName, int limit = 2}) {
    final places = getAll(cityName: cityName)
        .where((place) => place.isEditorsPick)
        .toList();

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
    return _source.any(
      (guide) => guide.cityName.toLowerCase() == normalized,
    );
  }

  @override
  List<PlaceCategory> get categories => PlaceCategory.values;
}
