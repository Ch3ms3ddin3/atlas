import 'package:flutter/material.dart';

/// Catégories de lieux utiles au Maroc.
enum PlaceCategory {
  jardin,
  monument,
  restaurant,
  cafe,
  musee,
  hammam,
  plage,
  souk,
}

/// Ordre d'affichage de la liste Explorer.
enum PlaceSort {
  /// Ordre éditorial du catalogue (défaut).
  catalog,

  /// Nom A → Z.
  nameAsc,

  /// Quartier, puis nom.
  neighborhood,

  /// Niveau de prix croissant.
  priceLevel,

  /// Sélections Atlas en tête, puis nom.
  editorsPick,
}

/// Lieu curaté avec informations pratiques.
class PlaceGuide {
  const PlaceGuide({
    required this.id,
    required this.name,
    required this.cityName,
    required this.category,
    required this.categoryLabel,
    required this.neighborhood,
    required this.priceLevel,
    required this.isEditorsPick,
    required this.imageColor,
    required this.summary,
    required this.practicalTips,
    this.bestTimeToVisit,
    this.mapsUrl,
  });

  final String id;
  final String name;
  final String cityName;
  final PlaceCategory category;
  final String categoryLabel;
  final String neighborhood;
  final String priceLevel;
  final bool isEditorsPick;
  final Color imageColor;
  final String summary;
  final List<String> practicalTips;
  final String? bestTimeToVisit;
  final String? mapsUrl;
}

/// Filtre de recherche pour la liste des lieux.
class PlaceSearchQuery {
  const PlaceSearchQuery({
    this.text = '',
    this.category,
    this.cityName,
    this.sort = PlaceSort.catalog,
    this.strictCity = false,
  });

  final String text;
  final PlaceCategory? category;
  final String? cityName;

  /// Tri appliqué après filtrage — [PlaceSort.catalog] conserve l'ordre source.
  final PlaceSort sort;

  /// Si `true`, ne remplace pas une ville non couverte par le repli Marrakech.
  final bool strictCity;
}
