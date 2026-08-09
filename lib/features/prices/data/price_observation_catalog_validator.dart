import '../../../core/location/morocco_cities.dart';
import '../domain/models/price_models.dart';
import '../domain/models/price_observation.dart';
import 'price_observation_catalog.dart';
import 'price_observation_query.dart';

/// Validation stricte du catalogue Price Intelligence (Wave 1).
abstract final class PriceObservationCatalogValidator {
  static List<String> validate([
    List<PriceObservationCatalogEntry>? source,
  ]) {
    final entries = source ?? PriceObservationCatalog.entries;
    final errors = <String>[];
    final slugs = <String>{};
    final nationalProductKeys = <String>{};

    if (entries.isEmpty) {
      errors.add('Catalogue vide.');
      return errors;
    }

    for (final entry in entries) {
      final prefix = entry.slug;

      if (entry.slug.trim().isEmpty) {
        errors.add('Slug vide.');
      } else if (!slugs.add(entry.slug)) {
        errors.add('Slug dupliqué: ${entry.slug}');
      }

      if (entry.itemName.trim().isEmpty) {
        errors.add('$prefix: item_name vide.');
      }
      if (entry.unitLabel.trim().isEmpty) {
        errors.add('$prefix: unit_label vide.');
      }
      if (entry.sourceName.trim().isEmpty) {
        errors.add('$prefix: sourceName vide.');
      }
      if (entry.sourceUrl.trim().isEmpty) {
        errors.add('$prefix: sourceUrl vide.');
      } else {
        final uri = Uri.tryParse(entry.sourceUrl);
        if (uri == null ||
            !uri.hasScheme ||
            (uri.scheme != 'https' && uri.scheme != 'http')) {
          errors.add('$prefix: sourceUrl invalide (${entry.sourceUrl}).');
        }
      }

      if (entry.currency != 'MAD') {
        errors.add('$prefix: currency doit être MAD (reçu ${entry.currency}).');
      }
      if (entry.currentAmountMad <= 0) {
        errors.add('$prefix: current_amount_mad doit être > 0.');
      }
      if (entry.minAmountMad != null && entry.minAmountMad! < 0) {
        errors.add('$prefix: min_amount_mad négatif.');
      }
      if (entry.maxAmountMad != null && entry.maxAmountMad! < 0) {
        errors.add('$prefix: max_amount_mad négatif.');
      }
      if (entry.minAmountMad != null &&
          entry.maxAmountMad != null &&
          entry.minAmountMad! > entry.maxAmountMad!) {
        errors.add('$prefix: min > max.');
      }
      if (entry.avgAmountMad != null) {
        if (entry.minAmountMad != null &&
            entry.avgAmountMad! < entry.minAmountMad!) {
          errors.add('$prefix: avg < min.');
        }
        if (entry.maxAmountMad != null &&
            entry.avgAmountMad! > entry.maxAmountMad!) {
          errors.add('$prefix: avg > max.');
        }
      }

      if (entry.scope == PriceObservationScope.national) {
        if (entry.cityName != PriceNationalCity.name) {
          errors.add(
            '$prefix: national doit avoir city_name = '
            '${PriceNationalCity.name} (reçu ${entry.cityName}).',
          );
        }
        final productKey = '${entry.category.name}|${entry.itemName}';
        if (!nationalProductKeys.add(productKey)) {
          errors.add(
            '$prefix: produit national dupliqué ($productKey).',
          );
        }
      } else if (!MoroccoCities.supportedNames.contains(entry.cityName)) {
        errors.add(
          '$prefix: city_name hors MoroccoCities (${entry.cityName}).',
        );
      }

      if (entry.verificationStatus != PriceVerificationStatus.verified) {
        errors.add('$prefix: verification_status doit être verified.');
      }
      if (!entry.isPublished) {
        errors.add('$prefix: is_published doit être true pour Wave 1.');
      }
      if (entry.confidence != PriceConfidence.high &&
          entry.confidence != PriceConfidence.medium) {
        errors.add('$prefix: confidence hors high|medium.');
      }
    }

    // Chaque ville Wave 1 doit recevoir city-specific + national via le filtre.
    final observations = entries.map((e) => e.toObservation()).toList();
    for (final city in PriceObservationCatalog.wave1Cities) {
      final filtered = PriceObservationQuery.filter(
        PriceIntelligenceQuery(cityName: city),
        source: observations,
      );
      if (filtered.isEmpty) {
        errors.add('Filtre repository vide pour $city.');
      }
    }

    return errors;
  }

  static void assertValid([List<PriceObservationCatalogEntry>? source]) {
    final errors = validate(source);
    if (errors.isNotEmpty) {
      throw StateError(
        'PriceObservationCatalog invalide:\n - ${errors.join('\n - ')}',
      );
    }
  }
}
