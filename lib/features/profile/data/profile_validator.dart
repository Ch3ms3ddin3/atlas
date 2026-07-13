import '../../../core/location/morocco_cities.dart';

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
      return const ProfileFieldError('Le prénom contient des caractères invalides.');
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

  static bool _containsControlCharacters(String value) {
    for (final codeUnit in value.codeUnits) {
      if (codeUnit < 32) return true;
    }
    return false;
  }
}
