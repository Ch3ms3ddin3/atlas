import '../favorite_entity_type.dart';
import 'favorite_key.dart';

/// État local ou distant d'un favori (actif ou tombstone de suppression).
class FavoriteRecord {
  const FavoriteRecord({
    required this.entityType,
    required this.entitySlug,
    required this.isActive,
    required this.updatedAt,
  });

  final FavoriteEntityType entityType;
  final String entitySlug;
  final bool isActive;
  final DateTime updatedAt;

  FavoriteKey get key =>
      FavoriteKey(entityType: entityType, entitySlug: entitySlug);

  FavoriteRecord copyWith({
    FavoriteEntityType? entityType,
    String? entitySlug,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return FavoriteRecord(
      entityType: entityType ?? this.entityType,
      entitySlug: entitySlug ?? this.entitySlug,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entityType': entityType.name,
      'entitySlug': entitySlug,
      'isActive': isActive,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  static FavoriteRecord? fromJson(Map<String, dynamic> json) {
    final entitySlug = json['entitySlug'] as String?;
    if (entitySlug == null || entitySlug.isEmpty) return null;

    final updatedAtRaw = json['updatedAt'] as String?;
    if (updatedAtRaw == null) return null;

    return FavoriteRecord(
      entityType: FavoriteEntityTypeLabels.fromStorage(
        json['entityType'] as String?,
      ),
      entitySlug: entitySlug,
      isActive: json['isActive'] as bool? ?? true,
      updatedAt: DateTime.parse(updatedAtRaw).toUtc(),
    );
  }
}
