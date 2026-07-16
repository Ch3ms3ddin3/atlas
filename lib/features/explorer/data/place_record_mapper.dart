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
      address: _optionalString(row['address']),
      latitude: _optionalDouble(row['latitude']),
      longitude: _optionalDouble(row['longitude']),
      phone: _optionalString(row['phone']),
      website: _optionalString(row['website']),
      email: _optionalString(row['email']),
      imageUrls: _readStringList(row['image_urls']),
      amenities: _readStringList(row['amenities']),
      accessibilityFeatures: _readStringList(row['accessibility_features']),
      openingHours: _readOpeningHours(row['opening_hours']),
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

  static double? _optionalDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
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
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  static PlaceOpeningHours? _readOpeningHours(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      final note = _optionalString(value['note']);
      final rawEntries = value['entries'];
      final entries = <PlaceHoursEntry>[];
      if (rawEntries is List) {
        for (final item in rawEntries) {
          if (item is! Map) continue;
          final day = _optionalString(item['day'] ?? item['day_label']);
          final hours = _optionalString(item['hours'] ?? item['hours_label']);
          if (day == null || hours == null) continue;
          entries.add(PlaceHoursEntry(dayLabel: day, hoursLabel: hours));
        }
      }
      final hours = PlaceOpeningHours(entries: entries, note: note);
      return hours.hasContent ? hours : null;
    }

    if (value is List) {
      final entries = <PlaceHoursEntry>[];
      for (final item in value) {
        if (item is! Map) continue;
        final day = _optionalString(item['day'] ?? item['day_label']);
        final hours = _optionalString(item['hours'] ?? item['hours_label']);
        if (day == null || hours == null) continue;
        entries.add(PlaceHoursEntry(dayLabel: day, hoursLabel: hours));
      }
      if (entries.isEmpty) return null;
      return PlaceOpeningHours(entries: entries);
    }

    return null;
  }
}
