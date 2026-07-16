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

/// Créneau horaire d'un jour — uniquement si fourni par le catalogue.
class PlaceHoursEntry {
  const PlaceHoursEntry({
    required this.dayLabel,
    required this.hoursLabel,
  });

  final String dayLabel;
  final String hoursLabel;
}

/// Horaires d'ouverture structurés — absents tant que non publiés.
class PlaceOpeningHours {
  const PlaceOpeningHours({
    this.entries = const [],
    this.note,
  });

  final List<PlaceHoursEntry> entries;
  final String? note;

  bool get hasContent =>
      entries.isNotEmpty || (note != null && note!.trim().isNotEmpty);
}

/// Lieu curaté avec informations pratiques.
///
/// Les champs optionnels restent nullables / vides pour accueillir de futures
/// colonnes Supabase sans redesign UI — les sections s'affichent seulement
/// lorsqu'une donnée réelle est présente.
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
    this.address,
    this.latitude,
    this.longitude,
    this.phone,
    this.website,
    this.email,
    this.imageUrls = const [],
    this.amenities = const [],
    this.accessibilityFeatures = const [],
    this.openingHours,
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

  /// Adresse complète — distincte du quartier affiché dans le hero.
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? website;
  final String? email;

  /// URLs d'images distantes — galerie masquée si vide.
  final List<String> imageUrls;
  final List<String> amenities;
  final List<String> accessibilityFeatures;
  final PlaceOpeningHours? openingHours;

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get hasAddress => address != null && address!.trim().isNotEmpty;

  bool get hasPhone => phone != null && phone!.trim().isNotEmpty;

  bool get hasWebsite => website != null && website!.trim().isNotEmpty;

  bool get hasEmail => email != null && email!.trim().isNotEmpty;

  bool get hasGallery => imageUrls.isNotEmpty;

  bool get hasAmenities => amenities.isNotEmpty;

  bool get hasAccessibility => accessibilityFeatures.isNotEmpty;

  bool get hasOpeningHours => openingHours?.hasContent ?? false;

  bool get hasPracticalTips => practicalTips.isNotEmpty;

  bool get hasBestTimeToVisit =>
      bestTimeToVisit != null && bestTimeToVisit!.trim().isNotEmpty;

  bool get hasContactActions =>
      hasCoordinates || hasPhone || hasWebsite || hasEmail;
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
