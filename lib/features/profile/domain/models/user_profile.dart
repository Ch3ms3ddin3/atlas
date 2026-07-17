/// Type d'utilisateur Atlas — influence les conseils affichés.
enum AtlasUserType {
  resident,
  mre,
  tourist,
  expatriate,
  student,
  business,
}

/// Langue préférée — stockée localement ; seul le français est actif en MVP.
enum AtlasLanguage {
  french,
  english,
  arabic,
}

/// Profil local de l'utilisateur — extensible (avatar URL, display name).
class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.preferredCity,
    required this.language,
    required this.userType,
    this.displayName,
    this.avatarUrl,
  });

  /// Prénom invité neutre (V1 private beta).
  static const defaultFirstName = 'Voyageur';
  static const defaultPreferredCity = 'Marrakech';
  static const defaultLanguage = AtlasLanguage.french;
  static const defaultUserType = AtlasUserType.resident;

  final String firstName;
  final String preferredCity;
  final AtlasLanguage language;
  final AtlasUserType userType;

  /// Nom affiché optionnel (OAuth / sync) — sinon [firstName].
  final String? displayName;

  /// Avatar URL uniquement (pas d'upload local pour l'instant).
  final String? avatarUrl;

  static const defaults = UserProfile(
    firstName: defaultFirstName,
    preferredCity: defaultPreferredCity,
    language: defaultLanguage,
    userType: defaultUserType,
  );

  String get resolvedDisplayName {
    final named = displayName?.trim();
    if (named != null && named.isNotEmpty) return named;
    return firstName;
  }

  UserProfile copyWith({
    String? firstName,
    String? preferredCity,
    AtlasLanguage? language,
    AtlasUserType? userType,
    String? displayName,
    String? avatarUrl,
    bool clearDisplayName = false,
    bool clearAvatarUrl = false,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      preferredCity: preferredCity ?? this.preferredCity,
      language: language ?? this.language,
      userType: userType ?? this.userType,
      displayName: clearDisplayName ? null : (displayName ?? this.displayName),
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
    );
  }
}

extension AtlasUserTypeLabels on AtlasUserType {
  String get label => switch (this) {
        AtlasUserType.resident => 'Résident',
        AtlasUserType.mre => 'MRE',
        AtlasUserType.tourist => 'Touriste',
        AtlasUserType.expatriate => 'Expatrié',
        AtlasUserType.student => 'Étudiant',
        AtlasUserType.business => 'Business',
      };

  static AtlasUserType fromStorage(String? value) {
    if (value == 'visitor') {
      // Ancien libellé « Visiteur » → Touriste.
      return AtlasUserType.tourist;
    }
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

  /// V1: français uniquement dans l'UI — arabe/RTL et anglais masqués
  /// (enums conservés pour la localisation future).
  static const List<AtlasLanguage> v1Selectable = [AtlasLanguage.french];

  static AtlasLanguage fromStorage(String? value) {
    return AtlasLanguage.values.firstWhere(
      (language) => language.name == value,
      orElse: () => UserProfile.defaultLanguage,
    );
  }
}
