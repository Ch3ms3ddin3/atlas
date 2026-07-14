import '../favorite_entity_type.dart';

/// Identifiant stable d'un favori.
class FavoriteKey {
  const FavoriteKey({
    required this.entityType,
    required this.entitySlug,
  });

  final FavoriteEntityType entityType;
  final String entitySlug;

  @override
  bool operator ==(Object other) {
    return other is FavoriteKey &&
        other.entityType == entityType &&
        other.entitySlug == entitySlug;
  }

  @override
  int get hashCode => Object.hash(entityType, entitySlug);

  @override
  String toString() => '${entityType.name}:$entitySlug';
}
