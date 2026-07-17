import '../domain/models/atlas_event.dart';

/// Convertit une ligne Supabase vers [AtlasEvent].
abstract final class EventRecordMapper {
  static AtlasEvent fromRow(Map<String, dynamic> row) {
    final event = tryFromRow(row);
    if (event == null) {
      throw FormatException('Ligne event invalide: $row');
    }
    return event;
  }

  static AtlasEvent? tryFromRow(Map<String, dynamic> row) {
    final slug = _requiredString(row['slug']);
    final title = _requiredString(row['title']);
    final description = _requiredString(row['description']);
    final source = _requiredString(row['source']);
    final startRaw = row['start_at'] as String?;
    if (slug == null ||
        title == null ||
        description == null ||
        source == null ||
        startRaw == null) {
      return null;
    }

    final startAt = DateTime.tryParse(startRaw);
    if (startAt == null) return null;

    DateTime? endAt;
    final endRaw = row['end_at'] as String?;
    if (endRaw != null) {
      endAt = DateTime.tryParse(endRaw);
    }

    DateTime? lastVerified;
    final verifiedRaw = row['last_verified_at'] as String?;
    if (verifiedRaw != null) {
      lastVerified = DateTime.tryParse(verifiedRaw)?.toUtc();
    }

    final reliability = EventReliabilityLabels.fromStorage(
      row['reliability'] as String?,
    );

    // Garde-fou : une date lunaire ne peut pas être « confirmed » sans éditeur.
    // provisional / estimated / confirmed restent tels que publiés.

    return AtlasEvent(
      id: slug,
      title: title,
      description: description,
      category: EventCategoryLabels.fromStorage(row['category'] as String?),
      startAt: DateTime(startAt.year, startAt.month, startAt.day),
      endAt: endAt == null
          ? null
          : DateTime(endAt.year, endAt.month, endAt.day),
      isAllDay: row['is_all_day'] as bool? ?? true,
      cityName: _optionalString(row['city_name']),
      source: source,
      sourceUrl: _optionalString(row['source_url']),
      lastVerifiedAt: lastVerified,
      reliability: reliability,
      priority: (row['priority'] as num?)?.round(),
      audienceTags: _audienceTags(row['audience_tags']),
    );
  }

  static Map<String, dynamic> toSeedRow(AtlasEvent event) {
    return {
      'slug': event.id,
      'title': event.title,
      'description': event.description,
      'category': event.category.name,
      'start_at': _dateKey(event.startAt),
      'end_at': _dateKey(event.effectiveEnd),
      'is_all_day': event.isAllDay,
      'city_name': event.cityName,
      'source': event.source,
      'source_url': event.sourceUrl,
      'last_verified_at': event.lastVerifiedAt?.toUtc().toIso8601String(),
      'reliability': event.reliability.name,
      'priority': event.priority,
      'audience_tags': [
        for (final tag in event.audienceTags) tag.name,
      ],
    };
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String? _requiredString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _optionalString(dynamic value) {
    if (value == null) return null;
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<EventAudienceTag> _audienceTags(dynamic value) {
    if (value is! List) return const [];
    final tags = <EventAudienceTag>[];
    for (final item in value) {
      final tag = EventAudienceTagLabels.tryParse(item?.toString());
      if (tag != null) tags.add(tag);
    }
    return tags;
  }
}
