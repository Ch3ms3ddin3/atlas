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

  /// Garde uniquement [a-z0-9] (utile pour Plus61 / +61 / place-plus61).
  static String compactAlphanumeric(String value) {
    final normalized = normalize(value);
    final buffer = StringBuffer();
    for (final unit in normalized.runes) {
      final char = String.fromCharCode(unit);
      final isLetter = unit >= 97 && unit <= 122;
      final isDigit = unit >= 48 && unit <= 57;
      if (isLetter || isDigit) buffer.write(char);
    }
    return buffer.toString();
  }

  /// Découpe les transitions lettres ↔ chiffres : `plus61` → `plus`, `61`.
  static List<String> alphanumericRuns(String value) {
    final compact = compactAlphanumeric(value);
    if (compact.isEmpty) return const [];
    return [
      for (final match in _letterOrDigitRun.allMatches(compact))
        match.group(0)!,
    ];
  }

  /// Suffixe de slug recherchable : `place-plus61` → `plus61`.
  static String slugSearchTail(String? placeId) {
    if (placeId == null || placeId.isEmpty) return '';
    final normalized = normalize(placeId);
    const prefix = 'place-';
    if (normalized.startsWith(prefix) && normalized.length > prefix.length) {
      return compactAlphanumeric(normalized.substring(prefix.length));
    }
    return compactAlphanumeric(normalized);
  }

  /// Champs recherchables d'un lieu (alignés sur [PlaceMapper.filter]).
  ///
  /// Inclut des formes élargies du nom (runs lettres/chiffres + slug) pour que
  /// `plus` matche `Plus61` / `place-plus61` même si le libellé distant est `+61`.
  static String searchableHaystack({
    required String name,
    required String summary,
    required String neighborhood,
    required String categoryLabel,
    String? placeId,
  }) {
    final parts = <String>[
      name,
      summary,
      neighborhood,
      categoryLabel,
      compactAlphanumeric(name),
      ...alphanumericRuns(name),
    ];
    final slugTail = slugSearchTail(placeId);
    if (slugTail.isNotEmpty) {
      parts.add(slugTail);
      parts.addAll(alphanumericRuns(slugTail));
    }
    return normalize(parts.join(' '));
  }

  static bool matchesQuery(String query, String haystackNormalized) {
    final needle = normalize(query);
    if (needle.isEmpty) return true;
    return haystackNormalized.contains(needle);
  }

  /// `true` si le lieu matche [query] (nom, résumé, quartier, catégorie, slug).
  ///
  /// Correspondance partielle, insensible à la casse / accents — pas de fuzzy.
  static bool placeMatches({
    required String query,
    required String name,
    required String summary,
    required String neighborhood,
    required String categoryLabel,
    String? categoryEnumName,
    String? placeId,
  }) {
    final needle = _needle(query);
    if (needle.isEmpty) return true;

    final haystack = searchableHaystack(
      name: name,
      summary: summary,
      neighborhood: neighborhood,
      categoryLabel: categoryLabel,
      placeId: placeId,
    );
    if (_haystackContainsNeedle(haystack, needle)) return true;

    if (categoryEnumName != null &&
        _haystackContainsNeedle(normalize(categoryEnumName), needle)) {
      return true;
    }
    return false;
  }

  /// Rang de pertinence (plus petit = mieux) pour une requête non vide.
  ///
  /// 0 — le nom / un run lettres-chiffres / le slug commence par la requête
  /// 1 — le nom (compact) ou slug contient la requête
  /// 2 — quartier / libellé de catégorie
  /// 3 — résumé uniquement
  /// 99 — aucun match (ne devrait pas arriver après filtrage)
  static int relevanceRank({
    required String query,
    required String name,
    required String summary,
    required String neighborhood,
    required String categoryLabel,
    String? placeId,
  }) {
    final needle = _needle(query);
    if (needle.isEmpty) return 0;

    if (_nameOrSlugPrefixMatch(name: name, placeId: placeId, needle: needle)) {
      return 0;
    }
    if (_nameOrSlugContains(name: name, placeId: placeId, needle: needle)) {
      return 1;
    }

    final normalizedNeighborhood = normalize(neighborhood);
    final normalizedCategory = normalize(categoryLabel);
    if (_haystackContainsNeedle(normalizedNeighborhood, needle) ||
        _haystackContainsNeedle(normalizedCategory, needle)) {
      return 2;
    }

    if (_haystackContainsNeedle(normalize(summary), needle)) return 3;
    return 99;
  }

  static String _needle(String query) {
    final normalized = normalize(query);
    if (normalized.isEmpty) return '';
    // Requête déjà normalisée (PlaceMapper) ou brute — compact si ponctuation.
    final compact = compactAlphanumeric(normalized);
    return compact.isNotEmpty ? compact : normalized;
  }

  static bool _haystackContainsNeedle(String haystack, String needle) {
    if (haystack.contains(needle)) return true;
    final compactHay = compactAlphanumeric(haystack);
    final compactNeedle = compactAlphanumeric(needle);
    if (compactNeedle.isEmpty) return false;
    return compactHay.contains(compactNeedle);
  }

  static bool _nameOrSlugPrefixMatch({
    required String name,
    required String? placeId,
    required String needle,
  }) {
    final candidates = <String>{
      normalize(name),
      compactAlphanumeric(name),
      ...alphanumericRuns(name),
      ...normalize(name).split(_tokenSplit).where((t) => t.isNotEmpty),
    };
    final slugTail = slugSearchTail(placeId);
    if (slugTail.isNotEmpty) {
      candidates.add(slugTail);
      candidates.addAll(alphanumericRuns(slugTail));
    }
    for (final token in candidates) {
      if (token.startsWith(needle)) return true;
    }
    return false;
  }

  static bool _nameOrSlugContains({
    required String name,
    required String? placeId,
    required String needle,
  }) {
    final candidates = <String>{
      normalize(name),
      compactAlphanumeric(name),
      slugSearchTail(placeId),
    };
    for (final token in candidates) {
      if (token.isNotEmpty && token.contains(needle)) return true;
    }
    return false;
  }

  static final _tokenSplit = RegExp(r'[^a-z0-9]+');
  static final _letterOrDigitRun = RegExp(r'[a-z]+|[0-9]+');

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
