import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/user_profile.dart';

/// Persiste le profil utilisateur localement.
class ProfilePreferencesStore {
  const ProfilePreferencesStore();

  static const firstNameKey = 'profile_first_name';
  static const preferredCityKey = 'profile_preferred_city';
  static const languageKey = 'profile_language';
  static const userTypeKey = 'profile_user_type';

  Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    return UserProfile(
      firstName: prefs.getString(firstNameKey) ?? UserProfile.defaultFirstName,
      preferredCity:
          prefs.getString(preferredCityKey) ?? UserProfile.defaultPreferredCity,
      language: AtlasLanguageLabels.fromStorage(prefs.getString(languageKey)),
      userType: AtlasUserTypeLabels.fromStorage(prefs.getString(userTypeKey)),
    );
  }

  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(firstNameKey, profile.firstName);
    await prefs.setString(preferredCityKey, profile.preferredCity);
    await prefs.setString(languageKey, profile.language.name);
    await prefs.setString(userTypeKey, profile.userType.name);
  }
}
