import '../domain/models/price_observation.dart';

/// Mapping SQL / JSON ↔ [PriceObservation]. Refuse les lignes non vérifiées.
abstract final class PriceObservationMapper {
  static PriceObservation? fromSupabaseRow(Map<String, dynamic> row) {
    final slug = row['slug'] as String?;
    final itemName = row['item_name'] as String?;
    final cityName = row['city_name'] as String?;
    final unitLabel = row['unit_label'] as String?;
    final source = row['source'] as String?;
    final category = PriceIntelligenceCategoryLabels.tryParse(
      row['category'] as String?,
    );
    final confidence = PriceConfidenceLabels.tryParse(
      row['confidence'] as String?,
    );
    final verification = PriceVerificationStatusLabels.tryParse(
      row['verification_status'] as String?,
    );
    final current = _asDouble(row['current_amount_mad']);
    final updatedRaw = row['last_updated_at'] as String?;
    final updatedAt =
        updatedRaw == null ? null : DateTime.tryParse(updatedRaw);

    if (slug == null ||
        slug.isEmpty ||
        itemName == null ||
        itemName.isEmpty ||
        cityName == null ||
        cityName.isEmpty ||
        unitLabel == null ||
        unitLabel.isEmpty ||
        source == null ||
        source.isEmpty ||
        category == null ||
        confidence == null ||
        verification == null ||
        current == null ||
        updatedAt == null) {
      return null;
    }

    // Client : uniquement les observations vérifiées.
    if (verification != PriceVerificationStatus.verified) return null;

    final currency = (row['currency'] as String?)?.trim();
    return PriceObservation(
      id: slug,
      itemName: itemName,
      category: category,
      cityName: cityName,
      district: _nullableTrimmed(row['district'] as String?),
      unitLabel: unitLabel,
      currentAmountMad: current,
      minAmountMad: _asDouble(row['min_amount_mad']),
      avgAmountMad: _asDouble(row['avg_amount_mad']),
      maxAmountMad: _asDouble(row['max_amount_mad']),
      currency: (currency == null || currency.isEmpty) ? 'MAD' : currency,
      lastUpdatedAt: updatedAt.toLocal(),
      source: source,
      sourceUrl: _nullableTrimmed(row['source_url'] as String?),
      confidence: confidence,
      verificationStatus: verification,
      userReportsCount: _asInt(row['user_reports_count']) ?? 0,
      atlasScore: _asInt(row['atlas_score']),
    );
  }

  static Map<String, dynamic> toCacheJson(PriceObservation item) {
    return {
      'slug': item.id,
      'item_name': item.itemName,
      'category': item.category.name,
      'city_name': item.cityName,
      'district': item.district,
      'unit_label': item.unitLabel,
      'current_amount_mad': item.currentAmountMad,
      'min_amount_mad': item.minAmountMad,
      'avg_amount_mad': item.avgAmountMad,
      'max_amount_mad': item.maxAmountMad,
      'currency': item.currency,
      'last_updated_at': item.lastUpdatedAt.toUtc().toIso8601String(),
      'source': item.source,
      'source_url': item.sourceUrl,
      'confidence': item.confidence.name,
      'verification_status': item.verificationStatus.name,
      'user_reports_count': item.userReportsCount,
      'atlas_score': item.atlasScore,
    };
  }

  static PriceObservation? fromCacheJson(Map<String, dynamic> json) {
    return fromSupabaseRow(json);
  }

  static String formatAmount(double amount, {String currency = 'MAD'}) {
    final hasDecimals = amount != amount.roundToDouble();
    final formatted = hasDecimals
        ? amount.toStringAsFixed(2)
        : amount.round().toString();
    return '$formatted $currency';
  }

  static String formatLastUpdated(DateTime at) {
    final d = at.day.toString().padLeft(2, '0');
    final m = at.month.toString().padLeft(2, '0');
    return 'Mis à jour le $d/$m/${at.year}';
  }

  static String? _nullableTrimmed(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
