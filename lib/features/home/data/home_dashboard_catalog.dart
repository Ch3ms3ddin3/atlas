import 'package:flutter/material.dart';

import '../domain/models/home_models.dart';
import '../../prices/domain/models/price_models.dart';
import '../../procedures/domain/models/procedure_models.dart';

/// Sélections et actions du tableau de bord — catalogues locaux uniquement.
abstract final class HomeDashboardCatalog {
  /// Actions rapides : navigation vers des surfaces Atlas existantes uniquement.
  static const quickActions = <QuickActionData>[
    QuickActionData(
      id: 'explorer',
      label: 'Lieux',
      icon: Icons.explore_outlined,
    ),
    QuickActionData(
      id: 'procedures',
      label: 'Démarches',
      icon: Icons.description_outlined,
    ),
    QuickActionData(
      id: 'prices',
      label: 'Prix',
      icon: Icons.payments_outlined,
    ),
    QuickActionData(
      id: 'profile',
      label: 'Profil',
      icon: Icons.person_outline_rounded,
    ),
  ];

  /// Démarches mises en avant sur l'accueil (CTA curatés, sans compteurs fictifs).
  static const curatedProcedureIds = <String>[
    'cin-renewal',
    'residence-card',
    'admission-temporaire',
  ];

  /// Résout les démarches curatées depuis le catalogue (ignore les slugs absents).
  static List<ProcedureGuide> resolveCuratedProcedures(
    Iterable<ProcedureGuide> Function() allGuides,
  ) {
    final byId = {
      for (final guide in allGuides()) guide.id: guide,
    };
    return [
      for (final id in curatedProcedureIds) ?byId[id],
    ];
  }

  /// Repères de prix utiles pour la ville courante (max [limit]).
  static List<PriceGuide> pickUsefulPriceIndicators(
    List<PriceGuide> cityGuides, {
    int limit = 4,
  }) {
    if (cityGuides.isEmpty || limit <= 0) return const [];

    const preferredCategories = <PriceCategory>[
      PriceCategory.transport,
      PriceCategory.foodAndCafes,
      PriceCategory.housing,
      PriceCategory.tourism,
      PriceCategory.services,
      PriceCategory.groceries,
    ];

    final picked = <PriceGuide>[];
    final seen = <String>{};

    for (final category in preferredCategories) {
      if (picked.length >= limit) break;
      for (final guide in cityGuides) {
        if (guide.category != category) continue;
        if (!seen.add(guide.id)) continue;
        picked.add(guide);
        break;
      }
    }

    for (final guide in cityGuides) {
      if (picked.length >= limit) break;
      if (!seen.add(guide.id)) continue;
      picked.add(guide);
    }

    return picked;
  }
}
