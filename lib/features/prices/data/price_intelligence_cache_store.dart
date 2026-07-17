import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/price_observation.dart';
import 'price_observation_mapper.dart';

/// Cache disque de la dernière réponse Supabase vérifiée.
class PriceIntelligenceCacheStore {
  const PriceIntelligenceCacheStore();

  static const prefsKey = 'price_intelligence_cache_v1';

  Future<List<PriceObservation>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final items = decoded['items'];
      if (items is! List) return const [];

      final parsed = <PriceObservation>[];
      for (final entry in items) {
        if (entry is! Map) continue;
        final item = PriceObservationMapper.fromCacheJson(
          Map<String, dynamic>.from(entry),
        );
        if (item != null) parsed.add(item);
      }
      return parsed;
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<PriceObservation> items) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'items': items.map(PriceObservationMapper.toCacheJson).toList(),
    };
    await prefs.setString(prefsKey, jsonEncode(payload));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey);
  }
}
