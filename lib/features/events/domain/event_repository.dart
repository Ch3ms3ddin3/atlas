import 'package:flutter/foundation.dart';

import 'models/atlas_event.dart';

/// Accès au calendrier éditorial Maroc.
abstract class EventRepository {
  static EventRepository? _instance;
  static EventRepository Function()? _factory;

  static EventRepository get instance {
    _instance ??= _factory?.call() ??
        (throw StateError(
          'EventRepository.registerFactory() must be called before use.',
        ));
    return _instance!;
  }

  factory EventRepository() => instance;

  static void registerFactory(EventRepository Function() factory) {
    _factory = factory;
    _instance = null;
  }

  @visibleForTesting
  static void resetForTest() {
    _instance = null;
    _factory = null;
  }

  Future<void> warmUp();

  List<AtlasEvent> getAll();

  AtlasEvent? findById(String id);

  List<AtlasEvent> today({String? cityName, DateTime? now});

  List<AtlasEvent> upcoming({
    String? cityName,
    DateTime? now,
    int limit = 5,
  });

  List<AtlasEvent> search(EventSearchQuery query);
}

/// Paramètres de filtre pour l'agenda.
class EventSearchQuery {
  const EventSearchQuery({
    this.cityName,
    this.category,
    this.includeNational = true,
    this.from,
    this.to,
  });

  final String? cityName;
  final EventCategory? category;
  final bool includeNational;
  final DateTime? from;
  final DateTime? to;
}
