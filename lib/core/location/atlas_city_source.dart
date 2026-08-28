/// Origine de la ville Atlas : GPS automatique ou choix utilisateur.
enum AtlasCitySource {
  auto,
  manual;

  static AtlasCitySource fromStorage(String? raw) {
    if (raw == AtlasCitySource.manual.name) return AtlasCitySource.manual;
    return AtlasCitySource.auto;
  }

  /// Marrakech par défaut (ancienne valeur) n'est pas un choix manuel.
  /// Toute autre ville Maroc persistée l'est (migration des profils existants).
  static AtlasCitySource inferLegacy({
    required String preferredCity,
    required String defaultPreferredCity,
    String? stored,
  }) {
    if (stored != null && stored.isNotEmpty) {
      return fromStorage(stored);
    }
    final trimmed = preferredCity.trim();
    if (trimmed.isEmpty) return AtlasCitySource.auto;
    if (trimmed.toLowerCase() == defaultPreferredCity.toLowerCase()) {
      return AtlasCitySource.auto;
    }
    return AtlasCitySource.manual;
  }
}
