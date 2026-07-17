import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/notifications/prayer_notification_lead_time.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../explorer/domain/models/place_models.dart';
import 'user_preferences_store.dart';
import 'user_preferences_sync_coordinator.dart';

class SupabaseUserPreferencesRepository {
  const SupabaseUserPreferencesRepository();

  SupabaseClient? get _client => SupabaseBootstrap.clientOrNull();

  Future<UserPreferencesRemoteSnapshot?> fetch(String userId) async {
    final client = _client;
    if (client == null) return null;
    try {
      final row = await client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return null;
      return fromRow(row);
    } catch (_) {
      return null;
    }
  }

  Future<bool> upsert({
    required String userId,
    required UserPreferencesSnapshot snapshot,
  }) async {
    final client = _client;
    if (client == null) return false;
    try {
      await client.from('user_preferences').upsert({
        'user_id': userId,
        'prayer_notification_lead_time': snapshot.prayerLeadTime.name,
        'at_notifications_enabled': snapshot.atNotificationsEnabled,
        'explorer_city':
            snapshot.explorerCity.isEmpty ? null : snapshot.explorerCity,
        'explorer_category': snapshot.explorerCategory?.name,
        'explorer_favorites_only': snapshot.explorerFavoritesOnly,
        'updated_at':
            (snapshot.localUpdatedAt ?? DateTime.now().toUtc()).toIso8601String(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static UserPreferencesRemoteSnapshot fromRow(Map<String, dynamic> row) {
    PlaceCategory? category;
    final rawCategory = row['explorer_category'] as String?;
    if (rawCategory != null) {
      for (final value in PlaceCategory.values) {
        if (value.name == rawCategory) {
          category = value;
          break;
        }
      }
    }
    return UserPreferencesRemoteSnapshot(
      prayerLeadTime: PrayerNotificationLeadTime.fromStorage(
        row['prayer_notification_lead_time'] as String?,
      ),
      atNotificationsEnabled:
          row['at_notifications_enabled'] as bool? ?? false,
      explorerCity: (row['explorer_city'] as String?) ?? '',
      explorerCategory: category,
      explorerFavoritesOnly: row['explorer_favorites_only'] as bool? ?? false,
      updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
    );
  }
}
