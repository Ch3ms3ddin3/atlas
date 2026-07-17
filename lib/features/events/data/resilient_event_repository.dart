import 'package:flutter/foundation.dart';

import '../../../core/editorial/editorial_catalog_load_state.dart';
import '../../../core/editorial/resilient_editorial_catalog.dart';
import '../domain/event_repository.dart';
import '../domain/models/atlas_event.dart';
import 'event_query.dart';
import 'local_event_repository.dart';
import 'supabase_event_repository.dart';

/// Événements : local immédiat (fériés fixes), puis refresh Supabase.
class ResilientEventRepository with ChangeNotifier implements EventRepository {
  ResilientEventRepository({
    LocalEventRepository? local,
    Future<List<AtlasEvent>> Function()? fetchRemote,
    Duration? fetchTimeout,
  }) : _catalog = ResilientEditorialCatalog<AtlasEvent>(
          localItems: (local ?? LocalEventRepository()).items,
          fetchRemote: fetchRemote ?? const SupabaseEventRepository().fetchAll,
          fetchTimeout: fetchTimeout,
        ) {
    _catalog.addListener(_onCatalogChanged);
  }

  final ResilientEditorialCatalog<AtlasEvent> _catalog;

  EditorialCatalogLoadState get loadState => _catalog.loadState;

  Object? get lastError => _catalog.lastError;

  bool get isUsingRemote => _catalog.isUsingRemote;

  List<AtlasEvent> get _source => _catalog.items;

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
  List<AtlasEvent> getAll() => List.unmodifiable(_source);

  @override
  AtlasEvent? findById(String id) => EventQuery.findById(id, source: _source);

  @override
  List<AtlasEvent> today({String? cityName, DateTime? now}) {
    return EventQuery.today(source: _source, cityName: cityName, now: now);
  }

  @override
  List<AtlasEvent> upcoming({
    String? cityName,
    DateTime? now,
    int limit = 5,
  }) {
    return EventQuery.upcoming(
      source: _source,
      cityName: cityName,
      now: now,
      limit: limit,
    );
  }

  @override
  List<AtlasEvent> search(EventSearchQuery query) {
    return EventQuery.filter(query, source: _source);
  }
}
