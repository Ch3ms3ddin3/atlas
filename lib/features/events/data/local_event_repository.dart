import '../domain/event_repository.dart';
import '../domain/models/atlas_event.dart';
import 'event_catalog.dart';
import 'event_query.dart';

/// Catalogue local — fériés civils fixes confirmés uniquement.
class LocalEventRepository implements EventRepository {
  LocalEventRepository({this._nowProvider});

  final DateTime? Function()? _nowProvider;

  List<AtlasEvent> get items =>
      EventCatalog.localFallback(reference: _nowProvider?.call());

  @override
  Future<void> warmUp() async {}

  @override
  List<AtlasEvent> getAll() => items;

  @override
  AtlasEvent? findById(String id) => EventQuery.findById(id, source: items);

  @override
  List<AtlasEvent> today({String? cityName, DateTime? now}) {
    return EventQuery.today(
      source: items,
      cityName: cityName,
      now: now ?? _nowProvider?.call(),
    );
  }

  @override
  List<AtlasEvent> upcoming({
    String? cityName,
    DateTime? now,
    int limit = 5,
  }) {
    return EventQuery.upcoming(
      source: items,
      cityName: cityName,
      now: now ?? _nowProvider?.call(),
      limit: limit,
    );
  }

  @override
  List<AtlasEvent> search(EventSearchQuery query) {
    return EventQuery.filter(query, source: items);
  }
}
