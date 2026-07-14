import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/user_profile.dart';
import 'profile_local_snapshot.dart';

/// Persiste le profil utilisateur et les métadonnées de synchronisation.
class ProfilePreferencesStore {
  const ProfilePreferencesStore();

  static const firstNameKey = 'profile_first_name';
  static const preferredCityKey = 'profile_preferred_city';
  static const languageKey = 'profile_language';
  static const userTypeKey = 'profile_user_type';
  static const localUpdatedAtKey = 'profile_local_updated_at';
  static const syncPendingKey = 'profile_sync_pending';

  Future<ProfileLocalSnapshot> loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = UserProfile(
      firstName: prefs.getString(firstNameKey) ?? UserProfile.defaultFirstName,
      preferredCity:
          prefs.getString(preferredCityKey) ?? UserProfile.defaultPreferredCity,
      language: AtlasLanguageLabels.fromStorage(prefs.getString(languageKey)),
      userType: AtlasUserTypeLabels.fromStorage(prefs.getString(userTypeKey)),
    );

    final localUpdatedAtRaw = prefs.getString(localUpdatedAtKey);
    return ProfileLocalSnapshot(
      profile: profile,
      localUpdatedAt: localUpdatedAtRaw == null
          ? null
          : DateTime.parse(localUpdatedAtRaw).toUtc(),
      syncPending: prefs.getBool(syncPendingKey) ?? false,
    );
  }

  Future<void> saveProfile(
    UserProfile profile, {
    required DateTime localUpdatedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(firstNameKey, profile.firstName);
    await prefs.setString(preferredCityKey, profile.preferredCity);
    await prefs.setString(languageKey, profile.language.name);
    await prefs.setString(userTypeKey, profile.userType.name);
    await prefs.setString(
      localUpdatedAtKey,
      localUpdatedAt.toUtc().toIso8601String(),
    );
  }

  Future<void> setSyncPending(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(syncPendingKey, true);
      return;
    }
    await prefs.remove(syncPendingKey);
  }
}
