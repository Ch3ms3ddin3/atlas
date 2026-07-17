import '../../../core/notifications/prayer_notification_lead_time.dart';
import '../../explorer/domain/models/place_models.dart';
import 'user_preferences_store.dart';

class UserPreferencesRemoteSnapshot {
  const UserPreferencesRemoteSnapshot({
    required this.prayerLeadTime,
    required this.atNotificationsEnabled,
    required this.explorerCity,
    required this.explorerCategory,
    required this.explorerFavoritesOnly,
    required this.updatedAt,
  });

  final PrayerNotificationLeadTime prayerLeadTime;
  final bool atNotificationsEnabled;
  final String explorerCity;
  final PlaceCategory? explorerCategory;
  final bool explorerFavoritesOnly;
  final DateTime updatedAt;
}

class UserPreferencesMergeResult {
  const UserPreferencesMergeResult({
    required this.snapshot,
    required this.changed,
    required this.shouldPush,
  });

  final UserPreferencesSnapshot snapshot;
  final bool changed;
  final bool shouldPush;
}

/// Fusion LWW — à égalité le local l'emporte (jamais d'écrasement silencieux).
abstract final class UserPreferencesSyncCoordinator {
  static UserPreferencesMergeResult merge({
    required UserPreferencesSnapshot local,
    UserPreferencesRemoteSnapshot? remote,
  }) {
    if (remote == null) {
      return UserPreferencesMergeResult(
        snapshot: local,
        changed: false,
        shouldPush: local.syncPending || local.localUpdatedAt != null,
      );
    }

    final localAt = local.localUpdatedAt;
    if (localAt == null) {
      final fromRemote = UserPreferencesSnapshot(
        prayerLeadTime: remote.prayerLeadTime,
        atNotificationsEnabled: remote.atNotificationsEnabled,
        explorerCity: remote.explorerCity,
        explorerCategory: remote.explorerCategory,
        explorerFavoritesOnly: remote.explorerFavoritesOnly,
        localUpdatedAt: remote.updatedAt,
      );
      return UserPreferencesMergeResult(
        snapshot: fromRemote,
        changed: true,
        shouldPush: false,
      );
    }

    final remoteWins = remote.updatedAt.isAfter(localAt);
    if (remoteWins && !local.syncPending) {
      final fromRemote = UserPreferencesSnapshot(
        prayerLeadTime: remote.prayerLeadTime,
        atNotificationsEnabled: remote.atNotificationsEnabled,
        explorerCity: remote.explorerCity,
        explorerCategory: remote.explorerCategory,
        explorerFavoritesOnly: remote.explorerFavoritesOnly,
        localUpdatedAt: remote.updatedAt,
      );
      return UserPreferencesMergeResult(
        snapshot: fromRemote,
        changed: true,
        shouldPush: false,
      );
    }

    return UserPreferencesMergeResult(
      snapshot: local,
      changed: false,
      shouldPush: true,
    );
  }
}
