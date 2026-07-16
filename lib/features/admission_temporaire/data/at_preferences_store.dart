import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/at_vehicle.dart';

/// Snapshot local des véhicules + préférences de rappels AT.
class AtLocalSnapshot {
  const AtLocalSnapshot({
    required this.vehicles,
    required this.notificationsEnabled,
    required this.notificationPromptShown,
    this.syncPending = false,
  });

  final List<AtVehicle> vehicles;
  final bool notificationsEnabled;
  final bool notificationPromptShown;

  /// Réservé à la sync Supabase future.
  final bool syncPending;

  List<AtVehicle> get activeVehicles =>
      vehicles.where((v) => v.isActive).toList(growable: false);
}

/// Persistance SharedPreferences — prêt pour syncPending / sync future.
class AtPreferencesStore {
  const AtPreferencesStore();

  static const vehiclesKey = 'at_vehicles_v1';
  static const notificationsEnabledKey = 'at_notifications_enabled';
  static const notificationPromptShownKey = 'at_notification_prompt_shown';
  static const syncPendingKey = 'at_vehicles_sync_pending';

  Future<AtLocalSnapshot> loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(vehiclesKey);
    final vehicles = <AtVehicle>[];

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is! Map) continue;
            final vehicle = AtVehicle.fromJson(
              Map<String, dynamic>.from(item),
            );
            if (vehicle != null) vehicles.add(vehicle);
          }
        }
      } catch (_) {
        // Cache corrompu → liste vide.
      }
    }

    return AtLocalSnapshot(
      vehicles: vehicles,
      notificationsEnabled: prefs.getBool(notificationsEnabledKey) ?? false,
      notificationPromptShown:
          prefs.getBool(notificationPromptShownKey) ?? false,
      syncPending: prefs.getBool(syncPendingKey) ?? false,
    );
  }

  Future<void> saveVehicles(List<AtVehicle> vehicles) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = vehicles.map((v) => v.toJson()).toList(growable: false);
    await prefs.setString(vehiclesKey, jsonEncode(payload));
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationsEnabledKey, enabled);
  }

  Future<void> setNotificationPromptShown(bool shown) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationPromptShownKey, shown);
  }

  Future<void> setSyncPending(bool pending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(syncPendingKey, pending);
  }
}
