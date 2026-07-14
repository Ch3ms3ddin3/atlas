import '../../../core/icons/atlas_material_icons.dart';
import '../domain/models/price_models.dart';

/// Convertit une ligne Supabase vers [PriceGuide].
abstract final class PriceRecordMapper {
  static PriceGuide fromRow(Map<String, dynamic> row) {
    final category = PriceCategory.values.firstWhere(
      (value) => value.name == row['category'],
      orElse: () => PriceCategory.services,
    );

    return PriceGuide(
      id: row['slug'] as String,
      name: row['name'] as String,
      cityName: row['city_name'] as String,
      category: category,
      categoryLabel: row['category_label'] as String,
      minAmountMad: row['min_amount_mad'] as int,
      maxAmountMad: row['max_amount_mad'] as int,
      averageAmountMad: row['average_amount_mad'] as int,
      unitLabel: row['unit_label'] as String,
      summary: row['summary'] as String,
      priceFactors: _readStringList(row['price_factors']),
      warningSigns: _readStringList(row['warning_signs']),
      negotiationTips: _readStringList(row['negotiation_tips']),
      lastUpdatedAt: DateTime.parse(row['last_updated_at'] as String),
      icon: AtlasMaterialIcons.resolve(row['icon_key'] as String?),
      sourceNote: row['source_note'] as String?,
      isTouristTrap: row['is_tourist_trap'] as bool? ?? false,
    );
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }
}
