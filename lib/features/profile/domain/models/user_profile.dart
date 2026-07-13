/// Type d'utilisateur Atlas — influence les conseils affichés.
enum AtlasUserType {
  resident,
  mre,
  visitor,
}

/// Langue préférée — stockée localement ; seul le français est actif en MVP.
enum AtlasLanguage {
  french,
  english,
  arabic,
}

/// Profil local de l'utilisateur — sans compte ni backend.
class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.preferredCity,
    required this.language,
    required this.userType,
  });

  static const defaultFirstName = 'Chemseddine';
  static const defaultPreferredCity = 'Marrakech';
  static const defaultLanguage = AtlasLanguage.french;
  static const defaultUserType = AtlasUserType.resident;

  final String firstName;
  final String preferredCity;
  final AtlasLanguage language;
  final AtlasUserType userType;

  static const defaults = UserProfile(
    firstName: defaultFirstName,
    preferredCity: defaultPreferredCity,
    language: defaultLanguage,
    userType: defaultUserType,
  );

  UserProfile copyWith({
    String? firstName,
    String? preferredCity,
    AtlasLanguage? language,
    AtlasUserType? userType,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      preferredCity: preferredCity ?? this.preferredCity,
      language: language ?? this.language,
      userType: userType ?? this.userType,
    );
  }
}

extension AtlasUserTypeLabels on AtlasUserType {
  String get label => switch (this) {
        AtlasUserType.resident => 'Résident',
        AtlasUserType.mre => 'MRE',
        AtlasUserType.visitor => 'Visiteur',
      };

  static AtlasUserType fromStorage(String? value) {
    return AtlasUserType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => UserProfile.defaultUserType,
    );
  }
}

extension AtlasLanguageLabels on AtlasLanguage {
  String get label => switch (this) {
        AtlasLanguage.french => 'Français',
        AtlasLanguage.english => 'English',
        AtlasLanguage.arabic => 'العربية',
      };

  static AtlasLanguage fromStorage(String? value) {
    return AtlasLanguage.values.firstWhere(
      (language) => language.name == value,
      orElse: () => UserProfile.defaultLanguage,
    );
  }
}
