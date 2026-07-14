import 'package:flutter/material.dart';

import '../domain/models/place_models.dart';

/// Convertit une ligne Supabase vers [PlaceGuide].
abstract final class PlaceRecordMapper {
  static PlaceGuide fromRow(Map<String, dynamic> row) {
    final category = PlaceCategory.values.firstWhere(
      (value) => value.name == row['category'],
      orElse: () => PlaceCategory.monument,
    );

    return PlaceGuide(
      id: row['slug'] as String,
      name: row['name'] as String,
      cityName: row['city_name'] as String,
      category: category,
      categoryLabel: row['category_label'] as String,
      neighborhood: row['neighborhood'] as String,
      priceLevel: row['price_level'] as String,
      isEditorsPick: row['is_editors_pick'] as bool? ?? false,
      imageColor: _parseColor(row['image_color'] as String?),
      summary: row['summary'] as String,
      practicalTips: _readStringList(row['practical_tips']),
      bestTimeToVisit: row['best_time_to_visit'] as String?,
      mapsUrl: row['maps_url'] as String?,
    );
  }

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF1A2332);
    final normalized = hex.replaceFirst('#', '');
    if (normalized.length != 6) return const Color(0xFF1A2332);
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return const Color(0xFF1A2332);
    return Color(0xFF000000 | value);
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }
}
