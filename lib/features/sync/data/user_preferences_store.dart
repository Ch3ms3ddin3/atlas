import 'package:shared_preferences/shared_preferences.dart';

import '../../explorer/domain/models/place_models.dart';
import '../../explorer/domain/place_browse_filters.dart';
import '../../../core/notifications/prayer_notification_lead_time.dart';

/// Snapshot local des préférences synchronisables.
class UserPreferencesSnapshot {
  const UserPreferencesSnapshot({
    required this.prayerLeadTime,
    required this.atNotificationsEnabled,
    required this.explorerCity,
    required this.explorerCategory,
    required this.explorerFavoritesOnly,
    this.localUpdatedAt,
    this.syncPending = false,
  });

  final PrayerNotificationLeadTime prayerLeadTime;
  final bool atNotificationsEnabled;
  final String explorerCity;
  final PlaceCategory? explorerCategory;
  final bool explorerFavoritesOnly;
  final DateTime? localUpdatedAt;
  final bool syncPending;
}

/// Persistance locale des préférences (notifications + filtres Explorer).
class UserPreferencesStore {
  const UserPreferencesStore();

  static const prayerKey = 'prayer_notification_lead_time';
  static const atNotificationsKey = 'at_notifications_enabled';
  static const explorerCityKey = 'explorer_filter_city';
  static const explorerCategoryKey = 'explorer_filter_category';
  static const explorerFavoritesKey = 'explorer_filter_favorites_only';
  static const localUpdatedAtKey = 'user_preferences_local_updated_at';
  static const syncPendingKey = 'user_preferences_sync_pending';

  Future<UserPreferencesSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final categoryRaw = prefs.getString(explorerCategoryKey);
    PlaceCategory? category;
    if (categoryRaw != null) {
      for (final value in PlaceCategory.values) {
        if (value.name == categoryRaw) {
          category = value;
          break;
        }
      }
    }

    final updatedRaw = prefs.getString(localUpdatedAtKey);
    return UserPreferencesSnapshot(
      prayerLeadTime:
          PrayerNotificationLeadTime.fromStorage(prefs.getString(prayerKey)),
      atNotificationsEnabled: prefs.getBool(atNotificationsKey) ?? false,
      explorerCity: prefs.getString(explorerCityKey) ?? '',
      explorerCategory: category,
      explorerFavoritesOnly: prefs.getBool(explorerFavoritesKey) ?? false,
      localUpdatedAt: updatedRaw == null
          ? null
          : DateTime.tryParse(updatedRaw)?.toUtc(),
      syncPending: prefs.getBool(syncPendingKey) ?? false,
    );
  }

  Future<void> save(UserPreferencesSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    if (snapshot.prayerLeadTime == PrayerNotificationLeadTime.disabled) {
      await prefs.remove(prayerKey);
    } else {
      await prefs.setString(prayerKey, snapshot.prayerLeadTime.name);
    }
    await prefs.setBool(atNotificationsKey, snapshot.atNotificationsEnabled);
    if (snapshot.explorerCity.isEmpty) {
      await prefs.remove(explorerCityKey);
    } else {
      await prefs.setString(explorerCityKey, snapshot.explorerCity);
    }
    if (snapshot.explorerCategory == null) {
      await prefs.remove(explorerCategoryKey);
    } else {
      await prefs.setString(
        explorerCategoryKey,
        snapshot.explorerCategory!.name,
      );
    }
    await prefs.setBool(
      explorerFavoritesKey,
      snapshot.explorerFavoritesOnly,
    );
    final stamp = snapshot.localUpdatedAt ?? DateTime.now().toUtc();
    await prefs.setString(localUpdatedAtKey, stamp.toIso8601String());
  }

  Future<void> setSyncPending(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(syncPendingKey, true);
    } else {
      await prefs.remove(syncPendingKey);
    }
  }

  /// Applique le snapshot aux filtres Explorer en mémoire.
  void applyExplorerFilters(UserPreferencesSnapshot snapshot) {
    PlaceBrowseFilters.instance.update(
      cityName: snapshot.explorerCity,
      category: snapshot.explorerCategory,
      clearCategory: snapshot.explorerCategory == null,
      favoritesOnly: snapshot.explorerFavoritesOnly,
    );
  }

  UserPreferencesSnapshot captureFromFilters({
    required PrayerNotificationLeadTime prayerLeadTime,
    required bool atNotificationsEnabled,
  }) {
    final filters = PlaceBrowseFilters.instance;
    return UserPreferencesSnapshot(
      prayerLeadTime: prayerLeadTime,
      atNotificationsEnabled: atNotificationsEnabled,
      explorerCity: filters.cityName,
      explorerCategory: filters.category,
      explorerFavoritesOnly: filters.favoritesOnly,
      localUpdatedAt: DateTime.now().toUtc(),
    );
  }
}
