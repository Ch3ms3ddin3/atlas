import 'dart:io';

import 'package:atlas/core/icons/atlas_material_icons.dart';
import 'package:atlas/features/events/data/event_catalog.dart';
import 'package:atlas/features/events/domain/models/atlas_event.dart';
import 'package:atlas/features/explorer/data/place_catalog.dart';
import 'package:atlas/features/explorer/domain/models/place_models.dart';
import 'package:atlas/features/prices/data/price_catalog.dart';
import 'package:atlas/features/prices/domain/models/price_models.dart';
import 'package:atlas/features/procedures/data/procedure_catalog.dart';
import 'package:atlas/features/procedures/domain/models/procedure_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('génère supabase/seed.sql depuis les catalogues Dart', () {
    final buffer = StringBuffer()
      ..writeln(
        '-- Généré par test/tool/generate_editorial_seed_test.dart',
      )
      ..writeln('BEGIN;')
      ..writeln()
      ..writeln(_truncate('procedures'))
      ..writeln(_truncate('places'))
      ..writeln(_truncate('prices'))
      ..writeln(_truncate('events'));

    for (final guide in ProcedureCatalog.guides) {
      buffer.writeln(_procedureInsert(guide));
    }

    buffer.writeln();
    for (final guide in PlaceCatalog.guides) {
      buffer.writeln(_placeInsert(guide));
    }

    buffer.writeln();
    for (final guide in PriceCatalog.guides) {
      buffer.writeln(_priceInsert(guide));
    }

    buffer.writeln();
    // Fériés civils fixes uniquement (2026–2027) — pas de dates inventées.
    for (final event in EventCatalog.fixedPublicHolidaysForYears([2026, 2027])) {
      buffer.writeln(_eventInsert(event));
    }

    buffer.writeln();
    buffer.writeln('COMMIT;');

    File('supabase/seed.sql').writeAsStringSync(buffer.toString());
  });
}

String _truncate(String table) =>
    'TRUNCATE TABLE $table RESTART IDENTITY CASCADE;';

String _procedureInsert(ProcedureGuide guide) {
  return '''
INSERT INTO procedures (
  slug, title, summary, category, category_label, estimated_duration,
  documents, steps, icon_key, official_url
) VALUES (
  ${_text(guide.id)},
  ${_text(guide.title)},
  ${_text(guide.summary)},
  ${_text(guide.category.name)},
  ${_text(guide.categoryLabel)},
  ${_text(guide.estimatedDuration)},
  ${_textArray(guide.documents)},
  ${_textArray(guide.steps)},
  ${_text(AtlasMaterialIcons.keyFor(guide.icon))},
  ${guide.officialUrl == null ? 'NULL' : _text(guide.officialUrl!)}
) ON CONFLICT (slug) DO NOTHING;''';
}

String _placeInsert(PlaceGuide guide) {
  return '''
INSERT INTO places (
  slug, name, city_name, category, category_label, neighborhood, price_level,
  is_editors_pick, image_color, summary, practical_tips, best_time_to_visit, maps_url,
  address, latitude, longitude, phone, website, email,
  image_urls, amenities, accessibility_features, opening_hours
) VALUES (
  ${_text(guide.id)},
  ${_text(guide.name)},
  ${_text(guide.cityName)},
  ${_text(guide.category.name)},
  ${_text(guide.categoryLabel)},
  ${_text(guide.neighborhood)},
  ${_text(guide.priceLevel)},
  ${guide.isEditorsPick},
  ${_text(_colorHex(guide.imageColor))},
  ${_text(guide.summary)},
  ${_textArray(guide.practicalTips)},
  ${guide.bestTimeToVisit == null ? 'NULL' : _text(guide.bestTimeToVisit!)},
  ${guide.mapsUrl == null ? 'NULL' : _text(guide.mapsUrl!)},
  ${guide.address == null ? 'NULL' : _text(guide.address!)},
  ${guide.latitude ?? 'NULL'},
  ${guide.longitude ?? 'NULL'},
  ${guide.phone == null ? 'NULL' : _text(guide.phone!)},
  ${guide.website == null ? 'NULL' : _text(guide.website!)},
  ${guide.email == null ? 'NULL' : _text(guide.email!)},
  ${_textArray(guide.imageUrls)},
  ${_textArray(guide.amenities)},
  ${_textArray(guide.accessibilityFeatures)},
  ${_openingHoursJson(guide.openingHours)}
) ON CONFLICT (slug) DO NOTHING;''';
}

String _openingHoursJson(PlaceOpeningHours? hours) {
  if (hours == null || !hours.hasContent) return 'NULL';
  final entries = hours.entries
      .map(
        (entry) =>
            '{"day": ${_jsonText(entry.dayLabel)}, '
            '"hours": ${_jsonText(entry.hoursLabel)}}',
      )
      .join(', ');
  final notePart = hours.note == null
      ? ''
      : ', "note": ${_jsonText(hours.note!)}';
  return '\'{"entries": [$entries]$notePart}\'::jsonb';
}

String _jsonText(String value) => '"${_escape(value).replaceAll('"', '\\"')}"';

String _priceInsert(PriceGuide guide) {
  return '''
INSERT INTO prices (
  slug, name, city_name, category, category_label,
  min_amount_mad, max_amount_mad, average_amount_mad, unit_label, summary,
  price_factors, warning_signs, negotiation_tips, icon_key, source_note,
  is_tourist_trap, last_updated_at
) VALUES (
  ${_text(guide.id)},
  ${_text(guide.name)},
  ${_text(guide.cityName)},
  ${_text(guide.category.name)},
  ${_text(guide.categoryLabel)},
  ${guide.minAmountMad},
  ${guide.maxAmountMad},
  ${guide.averageAmountMad},
  ${_text(guide.unitLabel)},
  ${_text(guide.summary)},
  ${_textArray(guide.priceFactors)},
  ${_textArray(guide.warningSigns)},
  ${_textArray(guide.negotiationTips)},
  ${_text(AtlasMaterialIcons.keyFor(guide.icon))},
  ${guide.sourceNote == null ? 'NULL' : _text(guide.sourceNote!)},
  ${guide.isTouristTrap},
  ${_text(guide.lastUpdatedAt.toUtc().toIso8601String())}
) ON CONFLICT (slug) DO NOTHING;''';
}

String _eventInsert(AtlasEvent event) {
  final end = event.effectiveEnd;
  final verified = event.lastVerifiedAt?.toUtc().toIso8601String();
  return '''
INSERT INTO events (
  slug, title, description, category, start_at, end_at, is_all_day,
  city_name, source, source_url, last_verified_at, reliability, priority,
  audience_tags
) VALUES (
  ${_text(event.id)},
  ${_text(event.title)},
  ${_text(event.description)},
  ${_text(event.category.name)},
  ${_text(_dateKey(event.startAt))},
  ${_text(_dateKey(end))},
  ${event.isAllDay},
  ${event.cityName == null ? 'NULL' : _text(event.cityName!)},
  ${_text(event.source)},
  ${event.sourceUrl == null ? 'NULL' : _text(event.sourceUrl!)},
  ${verified == null ? 'NULL' : _text(verified)},
  ${_text(event.reliability.name)},
  ${event.priority ?? 'NULL'},
  ${_textArray([for (final tag in event.audienceTags) tag.name])}
) ON CONFLICT (slug) DO NOTHING;''';
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _text(String value) => "'${_escape(value)}'";

String _textArray(List<String> values) {
  if (values.isEmpty) return 'ARRAY[]::text[]';
  return 'ARRAY[${values.map(_text).join(', ')}]';
}

String _escape(String value) => value.replaceAll("'", "''");

String _colorHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
