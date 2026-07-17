import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/trip.dart';

/// Persistance locale offline-first des voyages.
class ItineraryLocalStore {
  const ItineraryLocalStore();

  static const tripsKey = 'atlas_itineraries_v1';
  static const syncPendingKey = 'atlas_itineraries_sync_pending_v1';

  Future<List<Trip>> loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(tripsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          if (item is Map<String, dynamic>) Trip.fromJson(item),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveTrips(List<Trip> trips) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      tripsKey,
      jsonEncode(trips.map((t) => t.toJson()).toList()),
    );
  }

  Future<bool> isSyncPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(syncPendingKey) ?? false;
  }

  Future<void> setSyncPending(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(syncPendingKey, value);
  }
}
