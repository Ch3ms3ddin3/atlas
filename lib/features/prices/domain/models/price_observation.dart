import 'package:flutter/material.dart';

/// Catégories Price Intelligence v1.
enum PriceIntelligenceCategory {
  fuel,
  supermarkets,
  restaurants,
  coffee,
  fastFood,
  taxi,
  publicTransport,
  parking,
  realEstate,
  mobilePlans,
  internet,
  healthcare,
  pharmacy,
}

extension PriceIntelligenceCategoryLabels on PriceIntelligenceCategory {
  String get labelFr => switch (this) {
        PriceIntelligenceCategory.fuel => 'Carburant',
        PriceIntelligenceCategory.supermarkets => 'Supermarchés',
        PriceIntelligenceCategory.restaurants => 'Restaurants',
        PriceIntelligenceCategory.coffee => 'Café',
        PriceIntelligenceCategory.fastFood => 'Fast-food',
        PriceIntelligenceCategory.taxi => 'Taxi',
        PriceIntelligenceCategory.publicTransport => 'Transport public',
        PriceIntelligenceCategory.parking => 'Parking',
        PriceIntelligenceCategory.realEstate => 'Immobilier',
        PriceIntelligenceCategory.mobilePlans => 'Forfaits mobile',
        PriceIntelligenceCategory.internet => 'Internet',
        PriceIntelligenceCategory.healthcare => 'Santé',
        PriceIntelligenceCategory.pharmacy => 'Pharmacie',
      };

  IconData get icon => switch (this) {
        PriceIntelligenceCategory.fuel => Icons.local_gas_station_outlined,
        PriceIntelligenceCategory.supermarkets => Icons.shopping_cart_outlined,
        PriceIntelligenceCategory.restaurants => Icons.restaurant_outlined,
        PriceIntelligenceCategory.coffee => Icons.coffee_outlined,
        PriceIntelligenceCategory.fastFood => Icons.fastfood_outlined,
        PriceIntelligenceCategory.taxi => Icons.local_taxi_outlined,
        PriceIntelligenceCategory.publicTransport => Icons.directions_bus_outlined,
        PriceIntelligenceCategory.parking => Icons.local_parking_outlined,
        PriceIntelligenceCategory.realEstate => Icons.apartment_outlined,
        PriceIntelligenceCategory.mobilePlans => Icons.smartphone_outlined,
        PriceIntelligenceCategory.internet => Icons.wifi_outlined,
        PriceIntelligenceCategory.healthcare => Icons.medical_services_outlined,
        PriceIntelligenceCategory.pharmacy => Icons.local_pharmacy_outlined,
      };

  static PriceIntelligenceCategory? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final value in PriceIntelligenceCategory.values) {
      if (value.name == raw) return value;
    }
    return null;
  }
}

/// Niveau de confiance agrégé — jamais confondre avec la vérification.
enum PriceConfidence {
  high,
  medium,
  low,
}

extension PriceConfidenceLabels on PriceConfidence {
  String get labelFr => switch (this) {
        PriceConfidence.high => 'Confiance élevée',
        PriceConfidence.medium => 'Confiance moyenne',
        PriceConfidence.low => 'Confiance faible',
      };

  static PriceConfidence? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final value in PriceConfidence.values) {
      if (value.name == raw) return value;
    }
    return null;
  }
}

/// Statut de vérification éditoriale.
enum PriceVerificationStatus {
  verified,
  unverified,
  pending,
}

extension PriceVerificationStatusLabels on PriceVerificationStatus {
  String get labelFr => switch (this) {
        PriceVerificationStatus.verified => 'Vérifié',
        PriceVerificationStatus.unverified => 'Non vérifié',
        PriceVerificationStatus.pending => 'En vérification',
      };

  static PriceVerificationStatus? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final value in PriceVerificationStatus.values) {
      if (value.name == raw) return value;
    }
    return null;
  }
}

/// Tris supportés par la liste Intelligence.
enum PriceIntelligenceSort {
  atlasRecommendation,
  lowestPrice,
  highestPrice,
  recentlyUpdated,
}

extension PriceIntelligenceSortLabels on PriceIntelligenceSort {
  String get labelFr => switch (this) {
        PriceIntelligenceSort.atlasRecommendation => 'Recommandation Atlas',
        PriceIntelligenceSort.lowestPrice => 'Prix le plus bas',
        PriceIntelligenceSort.highestPrice => 'Prix le plus haut',
        PriceIntelligenceSort.recentlyUpdated => 'Mis à jour récemment',
      };
}

/// Observation de prix vérifiée — jamais inventée côté client.
class PriceObservation {
  const PriceObservation({
    required this.id,
    required this.itemName,
    required this.category,
    required this.cityName,
    required this.unitLabel,
    required this.currentAmountMad,
    required this.lastUpdatedAt,
    required this.source,
    required this.confidence,
    required this.verificationStatus,
    this.district,
    this.minAmountMad,
    this.avgAmountMad,
    this.maxAmountMad,
    this.currency = 'MAD',
    this.sourceUrl,
    this.userReportsCount = 0,
    this.atlasScore,
  });

  /// Slug stable (favoris).
  final String id;
  final String itemName;
  final PriceIntelligenceCategory category;
  final String cityName;
  final String? district;
  final String unitLabel;
  final double currentAmountMad;
  final double? minAmountMad;
  final double? avgAmountMad;
  final double? maxAmountMad;
  final String currency;
  final DateTime lastUpdatedAt;
  final String source;
  final String? sourceUrl;
  final PriceConfidence confidence;
  final PriceVerificationStatus verificationStatus;
  final int userReportsCount;
  final int? atlasScore;

  String get locationLabel {
    if (district == null || district!.trim().isEmpty) return cityName;
    return '$cityName · ${district!.trim()}';
  }

  bool get hasRange =>
      minAmountMad != null || avgAmountMad != null || maxAmountMad != null;
}

/// Filtre / recherche pour la liste Intelligence.
class PriceIntelligenceQuery {
  const PriceIntelligenceQuery({
    this.text = '',
    this.category,
    this.cityName,
    this.sort = PriceIntelligenceSort.atlasRecommendation,
  });

  final String text;
  final PriceIntelligenceCategory? category;
  final String? cityName;
  final PriceIntelligenceSort sort;
}
