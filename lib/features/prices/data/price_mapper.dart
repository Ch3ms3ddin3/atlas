import '../../../core/location/location_constants.dart';
import '../domain/models/price_models.dart';
import 'price_catalog.dart';

/// Filtre le catalogue et formate les montants.
abstract final class PriceMapper {
  static const categoryLabels = {
    PriceCategory.alimentation: 'Alimentation',
    PriceCategory.transport: 'Transport',
    PriceCategory.logement: 'Logement',
    PriceCategory.sante: 'Santé',
    PriceCategory.loisirs: 'Loisirs',
    PriceCategory.services: 'Services',
  };

  static String resolveCityName(String? cityName) {
    if (cityName == null || cityName.trim().isEmpty) {
      return LocationConstants.fallbackCity;
    }

    final normalized = cityName.trim().toLowerCase();
    final knownCities = PriceCatalog.guides
        .map((guide) => guide.cityName.toLowerCase())
        .toSet();

    if (knownCities.contains(normalized)) {
      return _canonicalCityName(normalized);
    }

    return LocationConstants.fallbackCity;
  }

  static List<PriceGuide> filter(PriceSearchQuery query) {
    final cityName = resolveCityName(query.cityName);
    final normalizedQuery = query.text.trim().toLowerCase();

    return PriceCatalog.guides.where((guide) {
      if (guide.cityName.toLowerCase() != cityName.toLowerCase()) {
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
      ].join(' ').toLowerCase();

      return haystack.contains(normalizedQuery);
    }).toList();
  }

  static PriceGuide? findById(String id) {
    for (final guide in PriceCatalog.guides) {
      if (guide.id == id) return guide;
    }
    return null;
  }

  static String formatAmount(int amountMad) {
    final formatted = _formatWithSpaces(amountMad);
    return '$formatted MAD';
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

  static String _canonicalCityName(String normalizedCity) {
    for (final guide in PriceCatalog.guides) {
      if (guide.cityName.toLowerCase() == normalizedCity) {
        return guide.cityName;
      }
    }
    return LocationConstants.fallbackCity;
  }
}
