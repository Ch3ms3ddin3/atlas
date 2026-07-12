import 'package:flutter/material.dart';

/// Catégories de prix moyens au Maroc.
enum PriceCategory {
  alimentation,
  transport,
  logement,
  sante,
  loisirs,
  services,
}

/// Repère de prix moyen pour le quotidien.
class PriceGuide {
  const PriceGuide({
    required this.id,
    required this.name,
    required this.cityName,
    required this.category,
    required this.categoryLabel,
    required this.averageAmountMad,
    required this.rangeLabel,
    required this.unitLabel,
    required this.summary,
    required this.practicalTips,
    required this.icon,
  });

  final String id;
  final String name;
  final String cityName;
  final PriceCategory category;
  final String categoryLabel;
  final int averageAmountMad;
  final String rangeLabel;
  final String unitLabel;
  final String summary;
  final List<String> practicalTips;
  final IconData icon;
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
