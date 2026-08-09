import 'package:flutter/material.dart';

import '../favorite_entity_type.dart';
import 'favorite_key.dart';

/// Favori résolu (ou non) pour l'affichage du hub.
class FavoriteHubEntry {
  const FavoriteHubEntry({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isResolved,
  });

  final FavoriteKey key;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isResolved;

  FavoriteEntityType get entityType => key.entityType;
  String get entitySlug => key.entitySlug;

  String get typeLabel => switch (entityType) {
    FavoriteEntityType.place => 'Lieu',
    FavoriteEntityType.procedure => 'Démarche',
    FavoriteEntityType.price => 'Prix',
  };
}
