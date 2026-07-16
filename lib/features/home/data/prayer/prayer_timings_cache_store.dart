import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistance des derniers horaires AlAdhan valides (jour + ville).
class PrayerTimingsCacheStore {
  const PrayerTimingsCacheStore();

  static const prefsKey = 'prayer_timings_cache_v1';

  Future<Map<String, String>?> load({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final entries = decoded['entries'];
      if (entries is! Map) return null;
      final key = cacheKey(latitude: latitude, longitude: longitude, date: date);
      final entry = entries[key];
      if (entry is! Map) return null;
      final timings = entry['timings'];
      if (timings is! Map) return null;
      return {
        for (final item in timings.entries)
          item.key.toString(): item.value.toString(),
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required double latitude,
    required double longitude,
    required DateTime date,
    required Map<String, String> timings,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = <String, dynamic>{};
    final raw = prefs.getString(prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final entries = decoded['entries'];
        if (entries is Map) {
          existing.addAll(Map<String, dynamic>.from(entries));
        }
      } catch (_) {
        // Remplace un cache corrompu.
      }
    }

    final key = cacheKey(latitude: latitude, longitude: longitude, date: date);
    existing[key] = {
      'timings': timings,
      'fetchedAt': DateTime.now().toUtc().toIso8601String(),
    };

    // Conserve un historique borné (ville × jours récents).
    if (existing.length > 40) {
      final keys = existing.keys.toList()..sort();
      for (final stale in keys.take(existing.length - 40)) {
        existing.remove(stale);
      }
    }

    await prefs.setString(
      prefsKey,
      jsonEncode({'entries': existing}),
    );
  }

  static String cacheKey({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) {
    final day =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return '${_round(latitude)}_${_round(longitude)}_$day';
  }

  static String _round(double value) => value.toStringAsFixed(4);
}
