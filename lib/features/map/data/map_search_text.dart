/// Normalisation de texte pour la recherche Explorer + Carte.
///
/// Le texte affiché reste inchangé ; on normalise seulement pour la comparaison.
abstract final class MapSearchText {
  /// Minuscules + suppression des diacritiques (é→e, ç→c, œ→oe, …).
  static String normalize(String value) {
    final lower = value.trim().toLowerCase();
    final buffer = StringBuffer();
    for (final unit in lower.runes) {
      final char = String.fromCharCode(unit);
      buffer.write(_fold[char] ?? char);
    }
    return buffer.toString();
  }

  /// Champs recherchables d'un lieu (alignés sur [PlaceMapper.filter]).
  static String searchableHaystack({
    required String name,
    required String summary,
    required String neighborhood,
    required String categoryLabel,
  }) {
    return normalize([name, summary, neighborhood, categoryLabel].join(' '));
  }

  static bool matchesQuery(String query, String haystackNormalized) {
    final needle = normalize(query);
    if (needle.isEmpty) return true;
    return haystackNormalized.contains(needle);
  }

  static const _fold = <String, String>{
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'ö': 'o',
    'õ': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
    'ñ': 'n',
    'ç': 'c',
    'œ': 'oe',
    'æ': 'ae',
  };
}
