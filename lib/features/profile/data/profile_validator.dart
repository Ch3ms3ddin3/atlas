import '../../../core/location/morocco_cities.dart';
import '../domain/models/user_profile.dart';

/// Résultat de validation d'un champ du profil.
class ProfileFieldError {
  const ProfileFieldError(this.message);

  final String message;
}

/// Valide les champs du profil avant enregistrement.
abstract final class ProfileValidator {
  static const maxFirstNameLength = 40;

  static ProfileFieldError? validateFirstName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return const ProfileFieldError('Le prénom est requis.');
    }
    if (trimmed.length > maxFirstNameLength) {
      return const ProfileFieldError(
        'Le prénom ne peut pas dépasser 40 caractères.',
      );
    }
    if (_containsControlCharacters(trimmed)) {
      return const ProfileFieldError(
        'Le prénom contient des caractères invalides.',
      );
    }
    return null;
  }

  static ProfileFieldError? validatePreferredCity(String value) {
    if (MoroccoCities.resolve(value) == null) {
      return const ProfileFieldError('Ville non reconnue.');
    }
    return null;
  }

  static bool isFormValid({
    required String firstName,
    required String preferredCity,
  }) {
    return validateFirstName(firstName) == null &&
        validatePreferredCity(preferredCity) == null;
  }

  static String sanitizeFirstName(String value) => value.trim();

  static String sanitizePreferredCity(String value) {
    return MoroccoCities.resolve(value)?.name ?? MoroccoCities.fallback.name;
  }

  /// Trim optional identity fields; blank / whitespace-only → `null`.
  /// Does not invent values and does not clear a present valid value.
  static String? sanitizeOptionalIdentityField(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (_containsControlCharacters(trimmed)) return null;
    return trimmed;
  }

  /// Sanitizes required form fields while preserving OAuth/sync identity.
  ///
  /// Returns `null` when first name / city fail validation — never drops
  /// [UserProfile.displayName] / [UserProfile.avatarUrl] as a side effect.
  static UserProfile? sanitizeForSave(UserProfile candidate) {
    final sanitized = UserProfile(
      firstName: sanitizeFirstName(candidate.firstName),
      preferredCity: sanitizePreferredCity(candidate.preferredCity),
      language: candidate.language,
      userType: candidate.userType,
      citySource: candidate.citySource,
      displayName: sanitizeOptionalIdentityField(candidate.displayName),
      avatarUrl: sanitizeOptionalIdentityField(candidate.avatarUrl),
    );

    if (!isFormValid(
      firstName: sanitized.firstName,
      preferredCity: sanitized.preferredCity,
    )) {
      return null;
    }
    return sanitized;
  }

  static bool _containsControlCharacters(String value) {
    for (final codeUnit in value.codeUnits) {
      if (codeUnit < 32) return true;
    }
    return false;
  }
}
