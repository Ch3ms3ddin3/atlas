import 'dart:convert';

import '../../admission_temporaire/domain/at_repository.dart';
import '../../auth/domain/auth_session.dart';
import '../../explorer/domain/place_browse_filters.dart';
import '../../favorites/domain/favorites_repository.dart';
import '../../profile/domain/profile_repository.dart';
import '../../../core/notifications/notification_preferences_store.dart';
import '../domain/cloud_sync_status.dart';

/// Export JSON des données utilisateur (pas de secrets).
abstract final class AtlasDataExport {
  static Future<String> buildJson({
    required AuthSession session,
    required ProfileRepository profile,
    required FavoritesRepository favorites,
    required AtRepository atRepository,
    CloudSyncStatus? syncStatus,
  }) async {
    final prayer = await const NotificationPreferencesStore().load();
    final filters = PlaceBrowseFilters.instance;
    final payload = <String, dynamic>{
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'account': {
        'kind': session.kind.name,
        'email': session.email,
        'providers': session.providers.map((p) => p.name).toList(),
      },
      'profile': {
        'first_name': profile.profile.firstName,
        'preferred_city': profile.profile.preferredCity,
        'language': profile.profile.language.name,
        'user_type': profile.profile.userType.name,
      },
      'preferences': {
        'prayer_notification_lead_time': prayer.name,
        'at_notifications_enabled': atRepository.notificationsEnabled,
        'explorer_city': filters.cityName,
        'explorer_category': filters.category?.name,
        'explorer_favorites_only': filters.favoritesOnly,
      },
      'sync': {
        'phase': syncStatus?.phase.name,
        'last_synced_at': syncStatus?.lastSyncedAt?.toIso8601String(),
      },
      'favorites': favorites.activeFavorites
          .map(
            (key) => {
              'entity_type': key.entityType.name,
              'entity_slug': key.entitySlug,
            },
          )
          .toList(),
      'at_vehicles': atRepository.activeVehicles
          .map(
            (v) => {
              'id': v.id,
              'label': v.label,
              'plate': v.plate,
              'country_code': v.countryCode,
              'type': v.type.name,
              'entry_date': v.entryDate.toIso8601String(),
              'expiry_date': v.expiryDate.toIso8601String(),
              'duration_days': v.durationDays,
            },
          )
          .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }
}
