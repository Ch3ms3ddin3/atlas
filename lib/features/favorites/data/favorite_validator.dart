import '../domain/favorite_entity_type.dart';

/// Validation applicative des favoris (pas de contrainte CHECK côté DB).
abstract final class FavoriteValidator {
  static const maxSlugLength = 120;

  static bool isValidSlug(String slug) {
    final trimmed = slug.trim();
    return trimmed.isNotEmpty && trimmed.length <= maxSlugLength;
  }

  static bool isValidFavorite({
    required FavoriteEntityType entityType,
    required String entitySlug,
  }) {
    return isValidSlug(entitySlug);
  }

  static String sanitizeSlug(String slug) => slug.trim();
}
