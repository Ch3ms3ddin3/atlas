import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/features/onboarding/data/onboarding_preferences_store.dart';

/// Prépare un démarrage post-onboarding pour les tests d'intégration.
void seedCompletedOnboarding([Map<String, Object>? extra]) {
  SharedPreferences.setMockInitialValues({
    OnboardingPreferencesStore.completedKey: true,
    ...?extra,
  });
}
