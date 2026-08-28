import 'package:flutter/foundation.dart';

import 'favorite_entity_type.dart';
import 'models/favorite_key.dart';

/// Accès aux favoris — indépendant de Supabase.
///
/// Les implémentations notifient les écouteurs après chaque changement
/// d'état actif (chargement, ajout, retrait, fusion distante).
abstract class FavoritesRepository extends ChangeNotifier {
  FavoritesRepository.base();

  bool get isLoaded;

  Set<FavoriteKey> get activeFavorites;

  bool isFavorite({
    required FavoriteEntityType entityType,
    required String entitySlug,
  });

  /// Charge l'état local (et déclenche une sync si l'implémentation le prévoit).
  Future<void> load();

  /// Relance la sync distante seulement si la précédente a échoué.
  ///
  /// No-op si aucune erreur, si une sync est déjà en cours, ou hors compte.
  /// Une ouverture d'écran = une tentative, jamais une boucle.
  Future<void> retryFailedRemoteSync() async {}

  /// Ajoute un favori. Retourne `false` si la validation échoue.
  Future<bool> addFavorite({
    required FavoriteEntityType entityType,
    required String entitySlug,
  });

  /// Retire un favori (tombstone locale). Retourne `false` si invalide.
  Future<bool> removeFavorite({
    required FavoriteEntityType entityType,
    required String entitySlug,
  });

  Future<bool> toggleFavorite({
    required FavoriteEntityType entityType,
    required String entitySlug,
  });
}
