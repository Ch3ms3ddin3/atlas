import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/home_models.dart';
import 'weather_mapper.dart';

/// Persistance de la dernière observation Open-Meteo valide.
class WeatherCacheStore {
  const WeatherCacheStore();

  static const prefsKey = 'weather_cache_v1';

  Future<WeatherData?> load({
    required double latitude,
    required double longitude,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final entries = decoded['entries'];
      if (entries is! Map) return null;
      final key = cacheKey(latitude: latitude, longitude: longitude);
      final entry = entries[key];
      if (entry is! Map) return null;
      return _fromEntry(Map<String, dynamic>.from(entry));
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required double latitude,
    required double longitude,
    required WeatherData data,
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

    final key = cacheKey(latitude: latitude, longitude: longitude);
    existing[key] = {
      'temperature': data.temperature,
      'feelsLike': data.feelsLike,
      'condition': data.condition,
      'weatherCode': data.weatherCode,
      'fetchedAt': (data.fetchedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'observedAtIso': data.observedAtIso,
      'windKmh': data.windKmh,
      'uvIndex': data.uvIndex,
      'rainProbabilityPercent': data.rainProbabilityPercent,
    };

    if (existing.length > 24) {
      final keys = existing.keys.toList()..sort();
      for (final stale in keys.take(existing.length - 24)) {
        existing.remove(stale);
      }
    }

    await prefs.setString(prefsKey, jsonEncode({'entries': existing}));
  }

  static String cacheKey({
    required double latitude,
    required double longitude,
  }) {
    return '${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}';
  }

  WeatherData? _fromEntry(Map<String, dynamic> entry) {
    final temperature = _asInt(entry['temperature']);
    final feelsLike = _asInt(entry['feelsLike']);
    final weatherCode = _asInt(entry['weatherCode']);
    final condition = entry['condition'] as String?;
    if (temperature == null ||
        feelsLike == null ||
        weatherCode == null ||
        condition == null ||
        condition.isEmpty) {
      return null;
    }

    final fetchedRaw = entry['fetchedAt'] as String?;
    return WeatherData(
      temperature: temperature,
      feelsLike: feelsLike,
      condition: condition,
      weatherCode: weatherCode,
      icon: WeatherMapper.iconForCode(weatherCode),
      fetchedAt: fetchedRaw == null ? null : DateTime.tryParse(fetchedRaw),
      observedAtIso: entry['observedAtIso'] as String?,
      windKmh: _asDouble(entry['windKmh']),
      uvIndex: _asDouble(entry['uvIndex']),
      rainProbabilityPercent: _asInt(entry['rainProbabilityPercent']),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
