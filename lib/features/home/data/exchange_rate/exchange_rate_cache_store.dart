import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/home_models.dart';
import 'exchange_rate_mapper.dart';

/// Persistance du dernier taux Frankfurter EUR/MAD valide.
class ExchangeRateCacheStore {
  const ExchangeRateCacheStore();

  static const prefsKey = 'exchange_rate_cache_v1';
  static const pairKey = 'EUR_MAD';

  Future<ExchangeRateData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final entry = decoded[pairKey];
      if (entry is! Map) return null;
      return _fromEntry(Map<String, dynamic>.from(entry));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(ExchangeRateData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      prefsKey,
      jsonEncode({
        pairKey: {
          'fromCurrency': data.fromCurrency,
          'toCurrency': data.toCurrency,
          'rate': data.rate,
          'sourceLabel': data.sourceLabel,
          'referenceDate': data.referenceDate,
          'fetchedAt': (data.fetchedAt ?? DateTime.now()).toUtc().toIso8601String(),
        },
      }),
    );
  }

  ExchangeRateData? _fromEntry(Map<String, dynamic> entry) {
    final rate = entry['rate'];
    final parsedRate = rate is num ? rate.toDouble() : double.tryParse('$rate');
    if (parsedRate == null || parsedRate <= 0) return null;

    final fetchedRaw = entry['fetchedAt'] as String?;
    return ExchangeRateData(
      fromCurrency: entry['fromCurrency'] as String? ?? 'EUR',
      toCurrency: entry['toCurrency'] as String? ?? 'MAD',
      rate: parsedRate,
      sourceLabel: entry['sourceLabel'] as String? ??
          ExchangeRateMapper.liveSourceLabel,
      referenceDate: entry['referenceDate'] as String? ?? '',
      fetchedAt: fetchedRaw == null ? null : DateTime.tryParse(fetchedRaw),
    );
  }
}
