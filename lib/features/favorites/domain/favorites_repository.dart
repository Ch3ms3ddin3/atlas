import 'package:flutter/foundation.dart';

import 'favorite_entity_type.dart';
import 'models/favorite_key.dart';

/// Accès aux favoris — indépendant de Supabase.
abstract class FavoritesRepository extends ChangeNotifier {
  FavoritesRepository.base();

  bool get isLoaded;

  Set<FavoriteKey> get activeFavorites;

  bool isFavorite({
    required FavoriteEntityType entityType,
    required String entitySlug,
  });

  Future<void> load();

  Future<bool> addFavorite({
    required FavoriteEntityType entityType,
    required String entitySlug,
  });

  Future<bool> removeFavorite({
    required FavoriteEntityType entityType,
    required String entitySlug,
  });

  Future<bool> toggleFavorite({
    required FavoriteEntityType entityType,
    required String entitySlug,
  });
}
