import '../domain/models/user_profile.dart';
import '../domain/profile_repository.dart';
import 'profile_preferences_store.dart';
import 'profile_validator.dart';

/// Profil local uniquement — repli permanent et tests hors-ligne.
class LocalProfileRepository extends ProfileRepository {
  LocalProfileRepository({
    ProfilePreferencesStore? store,
  })  : _store = store ?? const ProfilePreferencesStore(),
        super.base();

  final ProfilePreferencesStore _store;

  UserProfile _profile = UserProfile.defaults;
  bool _isLoaded = false;

  @override
  UserProfile get profile => _profile;

  @override
  bool get isLoaded => _isLoaded;

  @override
  Future<void> load() async {
    final snapshot = await _store.loadSnapshot();
    _profile = snapshot.profile;
    _isLoaded = true;
    notifyListeners();
  }

  @override
  Future<bool> save(UserProfile candidate) async {
    final sanitized = _sanitize(candidate);
    if (sanitized == null) return false;

    await _store.saveProfile(
      sanitized,
      localUpdatedAt: DateTime.now().toUtc(),
    );
    await _store.setSyncPending(false);
    _profile = sanitized;
    notifyListeners();
    return true;
  }

  UserProfile? _sanitize(UserProfile candidate) {
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
      return null;
    }
    return sanitized;
  }
}
