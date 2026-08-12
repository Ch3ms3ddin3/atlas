import 'price_observation_catalog.dart';

/// Émet le SQL d'upsert pour `price_observations` (dev seed + migration additive).
abstract final class PriceObservationCatalogSql {
  static String upsertAll({required String headerComment}) {
    final buffer = StringBuffer()
      ..writeln(headerComment.trim())
      ..writeln()
      ..writeln('BEGIN;')
      ..writeln()
      ..writeln(retireObsoleteNationalReplicas())
      ..writeln();

    for (final entry in PriceObservationCatalog.entries) {
      buffer.writeln(upsertOne(entry));
      buffer.writeln();
    }

    buffer.writeln('COMMIT;');
    return buffer.toString();
  }

  /// Retire les anciennes réplications ville×national (pré-correctif).
  static String retireObsoleteNationalReplicas() {
    final slugs = PriceObservationCatalog.retiredNationalReplicaSlugs;
    if (slugs.isEmpty) {
      return '-- (no obsolete national replica slugs)';
    }
    final list = slugs.map(_text).join(',\n  ');
    return '''
-- Retire Wave-1 city replicas of national tariffs (national-once architecture).
DELETE FROM price_observations
WHERE slug IN (
  $list
);''';
  }

  static String upsertOne(PriceObservationCatalogEntry entry) {
    final min = entry.minAmountMad == null
        ? 'NULL'
        : entry.minAmountMad.toString();
    final avg = entry.avgAmountMad == null
        ? 'NULL'
        : entry.avgAmountMad.toString();
    final max = entry.maxAmountMad == null
        ? 'NULL'
        : entry.maxAmountMad.toString();
    final district = entry.district == null ? 'NULL' : _text(entry.district!);
    final atlas = entry.atlasScore == null
        ? 'NULL'
        : entry.atlasScore.toString();
    final updated = entry.retrievedAt.toUtc().toIso8601String();

    return '''
INSERT INTO price_observations (
  slug, category, city_name, district, item_name, unit_label,
  current_amount_mad, min_amount_mad, avg_amount_mad, max_amount_mad,
  currency, last_updated_at, source, source_url, confidence,
  verification_status, user_reports_count, atlas_score, is_published
) VALUES (
  ${_text(entry.slug)},
  ${_text(entry.category.name)},
  ${_text(entry.cityName)},
  $district,
  ${_text(entry.itemName)},
  ${_text(entry.unitLabel)},
  ${entry.currentAmountMad},
  $min,
  $avg,
  $max,
  ${_text(entry.currency)},
  ${_text(updated)},
  ${_text(entry.sourceLabel)},
  ${_text(entry.sourceUrl)},
  ${_text(entry.confidence.name)},
  ${_text(entry.verificationStatus.name)},
  0,
  $atlas,
  ${entry.isPublished}
)
ON CONFLICT (slug) DO UPDATE SET
  category = EXCLUDED.category,
  city_name = EXCLUDED.city_name,
  district = EXCLUDED.district,
  item_name = EXCLUDED.item_name,
  unit_label = EXCLUDED.unit_label,
  current_amount_mad = EXCLUDED.current_amount_mad,
  min_amount_mad = EXCLUDED.min_amount_mad,
  avg_amount_mad = EXCLUDED.avg_amount_mad,
  max_amount_mad = EXCLUDED.max_amount_mad,
  currency = EXCLUDED.currency,
  last_updated_at = EXCLUDED.last_updated_at,
  source = EXCLUDED.source,
  source_url = EXCLUDED.source_url,
  confidence = EXCLUDED.confidence,
  verification_status = EXCLUDED.verification_status,
  atlas_score = EXCLUDED.atlas_score,
  is_published = EXCLUDED.is_published,
  updated_at = now();''';
  }

  static String _text(String value) => "'${value.replaceAll("'", "''")}'";
}
