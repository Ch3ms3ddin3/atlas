import '../../../core/datetime/casablanca_date_formatter.dart';
import '../../../core/location/location_constants.dart';
import '../domain/models/price_models.dart';
import 'price_catalog.dart';

/// Filtre le catalogue et formate les montants.
abstract final class PriceMapper {
  static const categoryLabels = {
    PriceCategory.transport: 'Transport',
    PriceCategory.foodAndCafes: 'Restauration & cafés',
    PriceCategory.groceries: 'Courses & épicerie',
    PriceCategory.services: 'Services',
    PriceCategory.tourism: 'Tourisme',
    PriceCategory.housing: 'Logement',
  };

  static String resolveCityName(
    String? cityName, {
    Iterable<PriceGuide>? guides,
  }) {
    if (cityName == null || cityName.trim().isEmpty) {
      return LocationConstants.fallbackCity;
    }

    final normalized = cityName.trim().toLowerCase();
    final catalog = guides ?? PriceCatalog.guides;
    final knownCities = catalog
        .where((guide) => !guide.isNational)
        .map((guide) => guide.cityName.toLowerCase())
        .toSet();

    if (knownCities.contains(normalized)) {
      return _canonicalCityName(normalized, catalog);
    }

    return LocationConstants.fallbackCity;
  }

  static List<PriceGuide> filter(
    PriceSearchQuery query, {
    List<PriceGuide>? source,
  }) {
    final catalog = source ?? PriceCatalog.guides;
    final cityName = resolveCityName(query.cityName, guides: catalog);
    final normalizedQuery = query.text.trim().toLowerCase();

    return catalog.where((guide) {
      if (!_matchesCity(guide, cityName)) {
        return false;
      }
      if (query.category != null && guide.category != query.category) {
        return false;
      }
      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        guide.name,
        guide.summary,
        guide.categoryLabel,
        guide.unitLabel,
        ...guide.priceFactors,
        ...guide.warningSigns,
        ...guide.negotiationTips,
      ].join(' ').toLowerCase();

      return haystack.contains(normalizedQuery);
    }).toList();
  }

  static PriceGuide? findById(
    String id, {
    List<PriceGuide>? source,
  }) {
    final catalog = source ?? PriceCatalog.guides;
    for (final guide in catalog) {
      if (guide.id == id) return guide;
    }
    return null;
  }

  static String formatAmount(int amountMad) {
    final formatted = _formatWithSpaces(amountMad);
    return '$formatted MAD';
  }

  static String formatRange(PriceGuide guide) {
    return '${_formatWithSpaces(guide.minAmountMad)} – '
        '${_formatWithSpaces(guide.maxAmountMad)} MAD';
  }

  static String formatLastUpdated(DateTime date) {
    return 'Mis à jour le ${CasablancaDateFormatter.formatShortDate(date)}';
  }

  static bool _matchesCity(PriceGuide guide, String cityName) {
    if (guide.isNational) return true;
    return guide.cityName.toLowerCase() == cityName.toLowerCase();
  }

  static String _formatWithSpaces(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final positionFromEnd = text.length - i;
      if (i > 0 && positionFromEnd % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  static String _canonicalCityName(
    String normalizedCity,
    Iterable<PriceGuide> guides,
  ) {
    for (final guide in guides) {
      if (guide.isNational) continue;
      if (guide.cityName.toLowerCase() == normalizedCity) {
        return guide.cityName;
      }
    }
    return LocationConstants.fallbackCity;
  }
}
