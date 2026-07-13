import 'package:flutter/material.dart';

/// Ville de repli pour les prix valables partout au Maroc.
abstract final class PriceNationalCity {
  static const name = 'National';
}

/// Catégories de prix moyens au Maroc.
enum PriceCategory {
  transport,
  foodAndCafes,
  groceries,
  services,
  tourism,
  housing,
}

/// Repère de prix moyen pour le quotidien.
class PriceGuide {
  const PriceGuide({
    required this.id,
    required this.name,
    required this.cityName,
    required this.category,
    required this.categoryLabel,
    required this.minAmountMad,
    required this.maxAmountMad,
    required this.averageAmountMad,
    required this.unitLabel,
    required this.summary,
    required this.priceFactors,
    required this.warningSigns,
    required this.negotiationTips,
    required this.lastUpdatedAt,
    required this.icon,
    this.sourceNote,
    this.isTouristTrap = false,
  });

  final String id;
  final String name;
  final String cityName;
  final PriceCategory category;
  final String categoryLabel;
  final int minAmountMad;
  final int maxAmountMad;
  final int averageAmountMad;
  final String unitLabel;
  final String summary;
  final List<String> priceFactors;
  final List<String> warningSigns;
  final List<String> negotiationTips;
  final DateTime lastUpdatedAt;
  final IconData icon;
  final String? sourceNote;
  final bool isTouristTrap;

  /// Prix valable dans toutes les villes couvertes.
  bool get isNational => cityName == PriceNationalCity.name;
}

/// Filtre de recherche pour la liste des prix.
class PriceSearchQuery {
  const PriceSearchQuery({
    this.text = '',
    this.category,
    this.cityName,
  });

  final String text;
  final PriceCategory? category;
  final String? cityName;
}
