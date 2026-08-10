import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/notifications/notification_preferences_store.dart';
import '../../admission_temporaire/data/at_preferences_store.dart';
import '../../assistant/data/assistant_history_store.dart';
import '../../assistant/data/assistant_token_usage_store.dart';
import '../../beta/data/beta_preferences_store.dart';
import '../../content_reports/data/content_reports_preferences_store.dart';
import '../../explorer/domain/place_browse_filters.dart';
import '../../favorites/data/favorites_preferences_store.dart';
import '../../itineraries/data/itinerary_local_store.dart';
import '../../profile/data/profile_preferences_store.dart';
import '../../sync/data/user_preferences_store.dart';
import '../../sync/domain/cloud_sync_status.dart';
import '../domain/auth_session.dart';

/// Identité locale précédemment liée au device (survit aux redémarrages).
class BoundLocalIdentity {
  const BoundLocalIdentity({this.kind, this.userId});

  final AuthSessionKind? kind;
  final String? userId;

  bool get isEmpty => kind == null && userId == null;
}

/// Frontière d'identité locale : empêche le merge/push des blobs d'un user
/// dans la session suivante (logout, delete, switch A→B, rotation anonyme).
abstract final class LocalUserDataIsolator {
  static const boundUserIdKey = 'atlas_bound_user_id';
  static const boundKindKey = 'atlas_bound_auth_kind';

  /// Première liaison sans historique : ne pas effacer.
  /// Sinon efface sur logout / delete / switch / rotation d'UID anonyme.
  /// Les bascules unavailable ↔ anonymous (dispo cloud) ne touchent pas aux
  /// données locales invité.
  static bool shouldClearLocal({
    required AuthSessionKind? previousKind,
    required String? previousUserId,
    required AuthSessionKind nextKind,
    required String? nextUserId,
  }) {
    if (previousKind == null && previousUserId == null) return false;
    if (previousUserId == nextUserId && previousKind == nextKind) {
      return false;
    }

    if (_isCloudAvailabilityFlip(previousKind, nextKind)) {
      return false;
    }

    // Quitter un compte authentifié (logout, delete, bascule).
    if (previousKind == AuthSessionKind.signedIn) return true;

    // Entrer dans un compte authentifié depuis une autre identité.
    if (nextKind == AuthSessionKind.signedIn &&
        previousUserId != nextUserId) {
      return true;
    }

    // Rotation d'UID anonyme (nouveau guest après sign-out).
    if (previousKind == AuthSessionKind.anonymous &&
        nextKind == AuthSessionKind.anonymous &&
        previousUserId != null &&
        nextUserId != null &&
        previousUserId != nextUserId) {
      return true;
    }

    return false;
  }

  static bool _isCloudAvailabilityFlip(
    AuthSessionKind? previousKind,
    AuthSessionKind nextKind,
  ) {
    if (previousKind == null) return false;
    final a = previousKind;
    final b = nextKind;
    return (a == AuthSessionKind.unavailable && b == AuthSessionKind.anonymous) ||
        (a == AuthSessionKind.anonymous && b == AuthSessionKind.unavailable) ||
        (a == AuthSessionKind.unavailable && b == AuthSessionKind.unavailable);
  }

  static Future<BoundLocalIdentity> loadBoundIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    final kindRaw = prefs.getString(boundKindKey);
    AuthSessionKind? kind;
    if (kindRaw != null) {
      for (final value in AuthSessionKind.values) {
        if (value.name == kindRaw) {
          kind = value;
          break;
        }
      }
    }
    return BoundLocalIdentity(
      kind: kind,
      userId: prefs.getString(boundUserIdKey),
    );
  }

  static Future<void> saveBoundIdentity({
    required AuthSessionKind kind,
    required String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(boundKindKey, kind.name);
    if (userId == null || userId.isEmpty) {
      await prefs.remove(boundUserIdKey);
    } else {
      await prefs.setString(boundUserIdKey, userId);
    }
  }

  /// Efface les stores personnels ; conserve onboarding / What's New / caches
  /// éditoriaux (prix, météo, etc.).
  static Future<void> clearPersistedUserData() async {
    await Future.wait([
      const ProfilePreferencesStore().clear(),
      const FavoritesPreferencesStore().clear(),
      const ContentReportsPreferencesStore().clear(),
      const UserPreferencesStore().clear(),
      const NotificationPreferencesStore().clear(),
      const CloudSyncStatusStore().clear(),
      const AtPreferencesStore().clear(),
      const ItineraryLocalStore().clear(),
      const AssistantHistoryStore().clear(),
      const AssistantTokenUsageStore().clear(),
      const BetaPreferencesStore().clearPendingFeedback(),
    ]);
    PlaceBrowseFilters.instance.clearForIdentityChange();
  }
}
