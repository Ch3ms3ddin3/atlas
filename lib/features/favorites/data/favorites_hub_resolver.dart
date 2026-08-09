import 'package:flutter/material.dart';

import '../../explorer/domain/place_repository.dart';
import '../../prices/domain/price_intelligence_repository.dart';
import '../../procedures/domain/procedure_repository.dart';
import '../domain/favorite_entity_type.dart';
import '../domain/models/favorite_hub_entry.dart';
import '../domain/models/favorite_key.dart';

/// Résout les clés favoris actives vers des titres réels — jamais inventés.
abstract final class FavoritesHubResolver {
  /// Ordre d'affichage hub (indépendant de l'ordre d'enum persisté).
  static const displayOrder = [
    FavoriteEntityType.place,
    FavoriteEntityType.procedure,
    FavoriteEntityType.price,
  ];

  static int _typeOrder(FavoriteEntityType type) => displayOrder.indexOf(type);

  static List<FavoriteHubEntry> resolve({
    required Iterable<FavoriteKey> activeFavorites,
    required PlaceRepository places,
    required ProcedureRepository procedures,
    required PriceIntelligenceRepository prices,
  }) {
    final entries = <FavoriteHubEntry>[];
    for (final key in activeFavorites) {
      entries.add(switch (key.entityType) {
        FavoriteEntityType.place => _resolvePlace(key, places),
        FavoriteEntityType.procedure => _resolveProcedure(key, procedures),
        FavoriteEntityType.price => _resolvePrice(key, prices),
      });
    }

    entries.sort((a, b) {
      final byType = _typeOrder(
        a.entityType,
      ).compareTo(_typeOrder(b.entityType));
      if (byType != 0) return byType;
      if (a.isResolved != b.isResolved) {
        return a.isResolved ? -1 : 1;
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return entries;
  }

  static FavoriteHubEntry _resolvePlace(
    FavoriteKey key,
    PlaceRepository places,
  ) {
    final place = places.findById(key.entitySlug);
    if (place == null) {
      return FavoriteHubEntry(
        key: key,
        title: 'Lieu indisponible',
        subtitle: 'Identifiant enregistré : ${key.entitySlug}',
        icon: Icons.place_outlined,
        isResolved: false,
      );
    }
    return FavoriteHubEntry(
      key: key,
      title: place.name,
      subtitle: '${place.categoryLabel} · ${place.cityName}',
      icon: Icons.place_outlined,
      isResolved: true,
    );
  }

  static FavoriteHubEntry _resolveProcedure(
    FavoriteKey key,
    ProcedureRepository procedures,
  ) {
    final guide = procedures.findById(key.entitySlug);
    if (guide == null) {
      return FavoriteHubEntry(
        key: key,
        title: 'Démarche indisponible',
        subtitle: 'Identifiant enregistré : ${key.entitySlug}',
        icon: Icons.description_outlined,
        isResolved: false,
      );
    }
    return FavoriteHubEntry(
      key: key,
      title: guide.title,
      subtitle: guide.categoryLabel,
      icon: Icons.description_outlined,
      isResolved: true,
    );
  }

  static FavoriteHubEntry _resolvePrice(
    FavoriteKey key,
    PriceIntelligenceRepository prices,
  ) {
    final observation = prices.findById(key.entitySlug);
    if (observation == null) {
      return FavoriteHubEntry(
        key: key,
        title: 'Prix indisponible',
        subtitle: 'Identifiant enregistré : ${key.entitySlug}',
        icon: Icons.payments_outlined,
        isResolved: false,
      );
    }
    return FavoriteHubEntry(
      key: key,
      title: observation.itemName,
      subtitle: observation.locationLabel,
      icon: Icons.payments_outlined,
      isResolved: true,
    );
  }
}
