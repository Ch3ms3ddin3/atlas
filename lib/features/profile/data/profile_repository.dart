import 'package:flutter/foundation.dart';

import '../domain/models/user_profile.dart';
import 'profile_preferences_store.dart';
import 'profile_validator.dart';

/// Accès au profil local — charge, valide et notifie les écrans connectés.
class ProfileRepository extends ChangeNotifier {
  ProfileRepository({
    ProfilePreferencesStore? store,
  }) : _store = store ?? const ProfilePreferencesStore();

  final ProfilePreferencesStore _store;

  UserProfile _profile = UserProfile.defaults;
  bool _isLoaded = false;

  UserProfile get profile => _profile;
  bool get isLoaded => _isLoaded;

  /// Charge le profil depuis le stockage local.
  Future<void> load() async {
    _profile = await _store.load();
    _isLoaded = true;
    notifyListeners();
  }

  /// Valide et enregistre le profil ; retourne false si invalide.
  Future<bool> save(UserProfile candidate) async {
    final sanitized = UserProfile(
      firstName: ProfileValidator.sanitizeFirstName(candidate.firstName),
      preferredCity:
          ProfileValidator.sanitizePreferredCity(candidate.preferredCity),
      language: candidate.language,
      userType: candidate.userType,
    );

    if (!ProfileValidator.isFormValid(
      firstName: sanitized.firstName,
      preferredCity: sanitized.preferredCity,
    )) {
      return false;
    }

    await _store.save(sanitized);
    _profile = sanitized;
    notifyListeners();
    return true;
  }
}
