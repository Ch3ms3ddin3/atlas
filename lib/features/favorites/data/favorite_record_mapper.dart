import '../domain/favorite_entity_type.dart';
import '../domain/models/favorite_record.dart';

/// Convertit les lignes Supabase vers les modèles favoris.
abstract final class FavoriteRecordMapper {
  static FavoriteRecord fromRow(Map<String, dynamic> row) {
    return FavoriteRecord(
      entityType: FavoriteEntityTypeLabels.fromStorage(
        row['entity_type'] as String?,
      ),
      entitySlug: row['entity_slug'] as String,
      isActive: row['is_active'] as bool? ?? true,
      updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
    );
  }

  static Map<String, dynamic> toRow({
    required String userId,
    required FavoriteRecord record,
  }) {
    return {
      'user_id': userId,
      'entity_type': FavoriteEntityTypeLabels.toStorage(record.entityType),
      'entity_slug': record.entitySlug,
      'is_active': record.isActive,
      'updated_at': record.updatedAt.toUtc().toIso8601String(),
    };
  }
}
