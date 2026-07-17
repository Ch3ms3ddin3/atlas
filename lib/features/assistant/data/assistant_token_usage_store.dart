import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/assistant_token_usage.dart';

/// Persistance locale de l'usage tokens / messages du jour.
class AssistantTokenUsageStore {
  const AssistantTokenUsageStore();

  static const dailyKey = 'assistant_daily_usage_v1';

  static String dayKeyFor(DateTime now) {
    final local = now.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<AssistantDailyUsage> loadToday([DateTime? now]) async {
    final key = dayKeyFor(now ?? DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(dailyKey);
    if (raw == null || raw.isEmpty) {
      return AssistantDailyUsage(
        dayKey: key,
        messageCount: 0,
        usage: const AssistantTokenUsage.zero(),
      );
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final loaded = AssistantDailyUsage.fromJson(json);
      if (loaded.dayKey != key) {
        return AssistantDailyUsage(
          dayKey: key,
          messageCount: 0,
          usage: const AssistantTokenUsage.zero(),
        );
      }
      return loaded;
    } catch (_) {
      return AssistantDailyUsage(
        dayKey: key,
        messageCount: 0,
        usage: const AssistantTokenUsage.zero(),
      );
    }
  }

  Future<void> save(AssistantDailyUsage daily) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(dailyKey, jsonEncode(daily.toJson()));
  }
}
