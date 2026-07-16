import 'package:flutter/material.dart';

import '../domain/models/place_models.dart';

/// Convertit une ligne Supabase vers [PlaceGuide].
abstract final class PlaceRecordMapper {
  /// Mapping strict — lève si les champs obligatoires sont absents ou invalides.
  static PlaceGuide fromRow(Map<String, dynamic> row) {
    final guide = tryFromRow(row);
    if (guide == null) {
      throw FormatException('Ligne place invalide: $row');
    }
    return guide;
  }

  /// Mapping tolérant — `null` si la ligne est malformée (à ignorer).
  static PlaceGuide? tryFromRow(Map<String, dynamic> row) {
    final slug = _requiredString(row['slug']);
    final name = _requiredString(row['name']);
    final cityName = _requiredString(row['city_name']);
    final categoryLabel = _requiredString(row['category_label']);
    final neighborhood = _requiredString(row['neighborhood']);
    final priceLevel = _requiredString(row['price_level']);
    final summary = _requiredString(row['summary']);

    if (slug == null ||
        name == null ||
        cityName == null ||
        categoryLabel == null ||
        neighborhood == null ||
        priceLevel == null ||
        summary == null) {
      return null;
    }

    final categoryName = row['category'] as String?;
    final category = PlaceCategory.values.firstWhere(
      (value) => value.name == categoryName,
      orElse: () => PlaceCategory.monument,
    );

    return PlaceGuide(
      id: slug,
      name: name,
      cityName: cityName,
      category: category,
      categoryLabel: categoryLabel,
      neighborhood: neighborhood,
      priceLevel: priceLevel,
      isEditorsPick: row['is_editors_pick'] as bool? ?? false,
      imageColor: _parseColor(row['image_color'] as String?),
      summary: summary,
      practicalTips: _readStringList(row['practical_tips']),
      bestTimeToVisit: _optionalString(row['best_time_to_visit']),
      mapsUrl: _optionalString(row['maps_url']),
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
