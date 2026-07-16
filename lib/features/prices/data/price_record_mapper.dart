import '../../../core/icons/atlas_material_icons.dart';
import '../domain/models/price_models.dart';

/// Convertit une ligne Supabase vers [PriceGuide].
abstract final class PriceRecordMapper {
  /// Mapping strict — lève si les champs obligatoires sont absents ou invalides.
  static PriceGuide fromRow(Map<String, dynamic> row) {
    final guide = tryFromRow(row);
    if (guide == null) {
      throw FormatException('Ligne price invalide: $row');
    }
    return guide;
  }

  /// Mapping tolérant — `null` si la ligne est malformée (à ignorer).
  static PriceGuide? tryFromRow(Map<String, dynamic> row) {
    final slug = _requiredString(row['slug']);
    final name = _requiredString(row['name']);
    final cityName = _requiredString(row['city_name']);
    final categoryLabel = _requiredString(row['category_label']);
    final unitLabel = _requiredString(row['unit_label']);
    final summary = _requiredString(row['summary']);
    final minAmountMad = _requiredInt(row['min_amount_mad']);
    final maxAmountMad = _requiredInt(row['max_amount_mad']);
    final averageAmountMad = _requiredInt(row['average_amount_mad']);
    final lastUpdatedAt = _requiredDateTime(row['last_updated_at']);

    if (slug == null ||
        name == null ||
        cityName == null ||
        categoryLabel == null ||
        unitLabel == null ||
        summary == null ||
        minAmountMad == null ||
        maxAmountMad == null ||
        averageAmountMad == null ||
        lastUpdatedAt == null) {
      return null;
    }

    final categoryName = row['category'] as String?;
    final category = PriceCategory.values.firstWhere(
      (value) => value.name == categoryName,
      orElse: () => PriceCategory.services,
    );

    return PriceGuide(
      id: slug,
      name: name,
      cityName: cityName,
      category: category,
      categoryLabel: categoryLabel,
      minAmountMad: minAmountMad,
      maxAmountMad: maxAmountMad,
      averageAmountMad: averageAmountMad,
      unitLabel: unitLabel,
      summary: summary,
      priceFactors: _readStringList(row['price_factors']),
      warningSigns: _readStringList(row['warning_signs']),
      negotiationTips: _readStringList(row['negotiation_tips']),
      lastUpdatedAt: lastUpdatedAt,
      icon: AtlasMaterialIcons.resolve(row['icon_key'] as String?),
      sourceNote: _optionalString(row['source_note']),
      isTouristTrap: row['is_tourist_trap'] as bool? ?? false,
    );
  }

  static String? _requiredString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  static String? _optionalString(dynamic value) {
    if (value == null) return null;
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _requiredInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static DateTime? _requiredDateTime(dynamic value) {
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      try {
        return DateTime.parse(value).toUtc();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }
}
