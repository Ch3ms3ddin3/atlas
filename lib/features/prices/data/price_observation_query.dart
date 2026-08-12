import '../domain/models/price_models.dart';
import '../domain/models/price_observation.dart';

/// Filtre, tri et highlights — sans inventer de données.
abstract final class PriceObservationQuery {
  /// Ville exacte **ou** observation nationale applicable.
  ///
  /// Les tarifs nationaux sont stockés une seule fois avec
  /// [PriceNationalCity.name] ; le filtre Prix les inclut pour chaque ville.
  static bool matchesCity(PriceObservation item, String? cityName) {
    final city = cityName?.trim().toLowerCase();
    if (city == null || city.isEmpty) return true;
    if (item.isNational) return true;
    return item.cityName.toLowerCase() == city;
  }

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

    final filtered = source.where((item) {
      if (item.verificationStatus != PriceVerificationStatus.verified) {
        return false;
      }
      if (query.category != null && item.category != query.category) {
        return false;
      }
      if (!matchesCity(item, query.cityName)) return false;
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
        items.sort((a, b) => a.currentAmountMad.compareTo(b.currentAmountMad));
      case PriceIntelligenceSort.highestPrice:
        items.sort((a, b) => b.currentAmountMad.compareTo(a.currentAmountMad));
      case PriceIntelligenceSort.recentlyUpdated:
        items.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
    }
  }

  /// Highlights city-aware : priorité ville, diversité de catégories.
  ///
  /// Si [strictCity] est vrai (Accueil), ne retombe jamais sur d'autres villes
  /// quand le pool ville/national est vide.
  static List<PriceObservation> highlights({
    required List<PriceObservation> source,
    String? cityName,
    int limit = 5,
    bool strictCity = false,
  }) {
    final capped = limit.clamp(1, 5);
    final verified = source
        .where((e) => e.verificationStatus == PriceVerificationStatus.verified)
        .toList();

    final forCity = verified.where((e) => matchesCity(e, cityName)).toList();

    final pool = strictCity
        ? forCity
        : (forCity.isNotEmpty ? forCity : verified);
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

  /// Accueil « Prix utiles » — max 2, ville stricte, préférence mobile + culture.
  ///
  /// [excludeIds] retire les observations déjà montrées ailleurs (ex. Utile
  /// maintenant) pour éviter la duplication Accueil.
  static List<PriceObservation> homeHighlights({
    required List<PriceObservation> source,
    required String? cityName,
    int limit = 2,
    Set<String> excludeIds = const {},
  }) {
    final capped = limit.clamp(1, 2);
    final pool = source
        .where(
          (e) =>
              e.verificationStatus == PriceVerificationStatus.verified &&
              matchesCity(e, cityName) &&
              !excludeIds.contains(e.id),
        )
        .toList();
    if (pool.isEmpty) return const [];

    final mobile = pool
        .where((e) => e.category == PriceIntelligenceCategory.mobilePlans)
        .toList();
    final culture = pool
        .where((e) => e.category == PriceIntelligenceCategory.culture)
        .toList();
    sortInPlace(mobile, PriceIntelligenceSort.atlasRecommendation);
    sortInPlace(culture, PriceIntelligenceSort.atlasRecommendation);

    final picked = <PriceObservation>[];
    void addFirst(List<PriceObservation> candidates) {
      if (picked.length >= capped || candidates.isEmpty) return;
      final next = candidates.first;
      if (!picked.any((e) => e.id == next.id)) {
        picked.add(next);
      }
    }

    addFirst(mobile);
    addFirst(culture);

    if (picked.length < capped) {
      final rest = List<PriceObservation>.from(pool);
      sortInPlace(rest, PriceIntelligenceSort.atlasRecommendation);
      for (final item in rest) {
        if (picked.length >= capped) break;
        if (!picked.any((e) => e.id == item.id)) {
          picked.add(item);
        }
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
