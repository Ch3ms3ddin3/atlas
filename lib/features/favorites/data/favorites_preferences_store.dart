import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/favorite_record.dart';
import 'favorites_local_snapshot.dart';

/// Persiste les favoris locaux et les métadonnées de synchronisation.
class FavoritesPreferencesStore {
  const FavoritesPreferencesStore();

  static const recordsKey = 'favorites_records_json';
  static const syncPendingKey = 'favorites_sync_pending';

  Future<FavoritesLocalSnapshot> loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final records = _decodeRecords(prefs.getString(recordsKey));
    return FavoritesLocalSnapshot(
      records: records,
      syncPending: prefs.getBool(syncPendingKey) ?? false,
    );
  }

  Future<void> saveRecords(List<FavoriteRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(records.map((record) => record.toJson()).toList());
    await prefs.setString(recordsKey, encoded);
  }

  Future<void> setSyncPending(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(syncPendingKey, true);
      return;
    }
    await prefs.remove(syncPendingKey);
  }

  static List<FavoriteRecord> _decodeRecords(String? raw) {
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>)
            ?FavoriteRecord.fromJson(item),
      ];
    } catch (_) {
      return const [];
    }
  }
}
