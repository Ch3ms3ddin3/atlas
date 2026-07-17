import '../domain/models/price_observation.dart';

/// Filtre, tri et highlights — sans inventer de données.
abstract final class PriceObservationQuery {
  static PriceObservation? findById(
    String id, {
    required List<PriceObservation> source,
  }) {
    for (final item in source) {
      if (item.id == id) return item;
    }
    return null;
  }

  static List<PriceObservation> filter(
    PriceIntelligenceQuery query, {
    required List<PriceObservation> source,
  }) {
    final text = query.text.trim().toLowerCase();
    final city = query.cityName?.trim().toLowerCase();

    final filtered = source.where((item) {
      if (item.verificationStatus != PriceVerificationStatus.verified) {
        return false;
      }
      if (query.category != null && item.category != query.category) {
        return false;
      }
      if (city != null && city.isNotEmpty) {
        if (item.cityName.toLowerCase() != city) return false;
      }
      if (text.isEmpty) return true;
      final haystack = [
        item.itemName,
        item.cityName,
        item.district ?? '',
        item.unitLabel,
        item.category.labelFr,
        item.source,
      ].join(' ').toLowerCase();
      return haystack.contains(text);
    }).toList();

    sortInPlace(filtered, query.sort);
    return filtered;
  }

  static void sortInPlace(
    List<PriceObservation> items,
    PriceIntelligenceSort sort,
  ) {
    int compareRecommendation(PriceObservation a, PriceObservation b) {
      final scoreCompare = _effectiveScore(b).compareTo(_effectiveScore(a));
      if (scoreCompare != 0) return scoreCompare;
      return b.lastUpdatedAt.compareTo(a.lastUpdatedAt);
    }

    switch (sort) {
      case PriceIntelligenceSort.atlasRecommendation:
        items.sort(compareRecommendation);
      case PriceIntelligenceSort.lowestPrice:
        items.sort(
          (a, b) => a.currentAmountMad.compareTo(b.currentAmountMad),
        );
      case PriceIntelligenceSort.highestPrice:
        items.sort(
          (a, b) => b.currentAmountMad.compareTo(a.currentAmountMad),
        );
      case PriceIntelligenceSort.recentlyUpdated:
        items.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
    }
  }

  /// Highlights city-aware : priorité ville, diversité de catégories.
  static List<PriceObservation> highlights({
    required List<PriceObservation> source,
    String? cityName,
    int limit = 5,
  }) {
    final capped = limit.clamp(3, 5);
    final city = cityName?.trim().toLowerCase();
    final verified = source
        .where((e) => e.verificationStatus == PriceVerificationStatus.verified)
        .toList();

    final forCity = city == null || city.isEmpty
        ? verified
        : verified
            .where((e) => e.cityName.toLowerCase() == city)
            .toList();

    final pool = forCity.isNotEmpty ? forCity : verified;
    if (pool.isEmpty) return const [];

    sortInPlace(pool, PriceIntelligenceSort.atlasRecommendation);

    final picked = <PriceObservation>[];
    final seenCategories = <PriceIntelligenceCategory>{};

    for (final item in pool) {
      if (picked.length >= capped) break;
      if (seenCategories.add(item.category)) {
        picked.add(item);
      }
    }
    for (final item in pool) {
      if (picked.length >= capped) break;
      if (!picked.any((e) => e.id == item.id)) {
        picked.add(item);
      }
    }
    return picked;
  }

  static int _effectiveScore(PriceObservation item) {
    if (item.atlasScore != null) return item.atlasScore!;
    final confidenceWeight = switch (item.confidence) {
      PriceConfidence.high => 30,
      PriceConfidence.medium => 15,
      PriceConfidence.low => 5,
    };
    final reports = item.userReportsCount.clamp(0, 20);
    final ageDays = DateTime.now().difference(item.lastUpdatedAt).inDays;
    final freshness = (30 - ageDays.clamp(0, 30)).clamp(0, 30);
    return confidenceWeight + reports + freshness;
  }
}
