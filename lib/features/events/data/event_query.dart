import '../domain/event_repository.dart';
import '../domain/models/atlas_event.dart';

/// Filtre et requêtes calendrier (dates civiles Africa/Casablanca).
abstract final class EventQuery {
  static DateTime casablancaNow([DateTime? referenceUtc]) {
    final utc = (referenceUtc ?? DateTime.now()).toUtc();
    return utc.add(const Duration(hours: 1));
  }

  static DateTime calendarDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool coversDay(AtlasEvent event, DateTime day) {
    final d = calendarDay(day);
    final start = calendarDay(event.startAt);
    final end = calendarDay(event.effectiveEnd);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  static bool matchesCity(AtlasEvent event, String? cityName) {
    if (event.isNational) return true;
    if (cityName == null || cityName.trim().isEmpty) return true;
    return event.cityName!.trim().toLowerCase() == cityName.trim().toLowerCase();
  }

  static List<AtlasEvent> filter(
    EventSearchQuery query, {
    required List<AtlasEvent> source,
  }) {
    final from = query.from == null ? null : calendarDay(query.from!);
    final to = query.to == null ? null : calendarDay(query.to!);

    final results = source.where((event) {
      if (query.category != null && event.category != query.category) {
        return false;
      }

      final city = query.cityName?.trim();
      if (city != null && city.isNotEmpty) {
        final isCityMatch = event.cityName != null &&
            event.cityName!.trim().toLowerCase() == city.toLowerCase();
        final isNational = event.isNational && query.includeNational;
        if (!isCityMatch && !isNational) return false;
      }

      if (from != null && calendarDay(event.effectiveEnd).isBefore(from)) {
        return false;
      }
      if (to != null && calendarDay(event.startAt).isAfter(to)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final byStart = a.startAt.compareTo(b.startAt);
        if (byStart != 0) return byStart;
        final ap = a.priority ?? 100;
        final bp = b.priority ?? 100;
        final byPriority = ap.compareTo(bp);
        if (byPriority != 0) return byPriority;
        return a.title.compareTo(b.title);
      });

    return results;
  }

  static List<AtlasEvent> today({
    required List<AtlasEvent> source,
    String? cityName,
    DateTime? now,
  }) {
    final day = calendarDay(now ?? casablancaNow());
    return filter(
      EventSearchQuery(
        cityName: cityName,
        includeNational: true,
        from: day,
        to: day,
      ),
      source: source,
    ).where((e) => coversDay(e, day)).toList();
  }

  static List<AtlasEvent> upcoming({
    required List<AtlasEvent> source,
    String? cityName,
    DateTime? now,
    int limit = 5,
  }) {
    final day = calendarDay(now ?? casablancaNow());
    final tomorrow = day.add(const Duration(days: 1));
    final filtered = filter(
      EventSearchQuery(
        cityName: cityName,
        includeNational: true,
        from: tomorrow,
      ),
      source: source,
    );
    if (limit <= 0) return filtered;
    return filtered.take(limit).toList();
  }

  static AtlasEvent? findById(String id, {required List<AtlasEvent> source}) {
    for (final event in source) {
      if (event.id == id) return event;
    }
    return null;
  }
}
