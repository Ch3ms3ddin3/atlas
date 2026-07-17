import 'package:shared_preferences/shared_preferences.dart';

import '../../profile/data/profile_preferences_store.dart';

/// Persistance du parcours d'accueil — local-first, prêt pour un sync futur.
class OnboardingPreferencesStore {
  const OnboardingPreferencesStore();

  static const completedKey = 'onboarding_completed';
  static const versionKey = 'onboarding_version';
  static const currentVersion = 1;

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(completedKey) ?? false) return true;

    // Migration : profil déjà personnalisé avant l'introduction du parcours.
    if (prefs.containsKey(ProfilePreferencesStore.localUpdatedAtKey)) {
      await markCompleted();
      return true;
    }
    return false;
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(completedKey, true);
    await prefs.setInt(versionKey, currentVersion);
  }

  /// Réinitialisation explicite uniquement (réglages / tests).
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(completedKey);
    await prefs.remove(versionKey);
  }
}
