/// Catégories d'événements Atlas.
enum EventCategory {
  publicHoliday,
  religious,
  schoolHoliday,
  nationalEvent,
  culturalFestival,
  sports,
  travelPeak,
}

extension EventCategoryLabels on EventCategory {
  String get labelFr => switch (this) {
        EventCategory.publicHoliday => 'Jours fériés',
        EventCategory.religious => 'Dates religieuses',
        EventCategory.schoolHoliday => 'Vacances scolaires',
        EventCategory.nationalEvent => 'Événements nationaux',
        EventCategory.culturalFestival => 'Festivals culturels',
        EventCategory.sports => 'Sport',
        EventCategory.travelPeak => 'Affluence / voyage',
      };

  static EventCategory fromStorage(String? raw) {
    return EventCategory.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => EventCategory.nationalEvent,
    );
  }
}

/// Fiabilité éditoriale — jamais présenter un estimé comme confirmé.
enum EventReliability {
  confirmed,
  provisional,
  estimated,
}

extension EventReliabilityLabels on EventReliability {
  String get labelFr => switch (this) {
        EventReliability.confirmed => 'Confirmé',
        EventReliability.provisional => 'Provisoire',
        EventReliability.estimated => 'Estimé',
      };

  static EventReliability fromStorage(String? raw) {
    return EventReliability.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => EventReliability.provisional,
    );
  }
}

/// Public cible optionnel.
enum EventAudienceTag {
  resident,
  mre,
  visitor,
  expat,
}

extension EventAudienceTagLabels on EventAudienceTag {
  String get labelFr => switch (this) {
        EventAudienceTag.resident => 'Résident',
        EventAudienceTag.mre => 'MRE',
        EventAudienceTag.visitor => 'Visiteur',
        EventAudienceTag.expat => 'Expatrié',
      };

  static EventAudienceTag? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final value in EventAudienceTag.values) {
      if (value.name == raw) return value;
    }
    return null;
  }
}

/// Événement éditorial Maroc — dates sourcées, jamais inventées.
class AtlasEvent {
  const AtlasEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.startAt,
    required this.isAllDay,
    required this.source,
    required this.reliability,
    this.endAt,
    this.cityName,
    this.sourceUrl,
    this.lastVerifiedAt,
    this.priority,
    this.audienceTags = const [],
  });

  /// Slug stable (favoris / sync futurs).
  final String id;
  final String title;
  final String description;
  final EventCategory category;
  final DateTime startAt;
  final DateTime? endAt;
  final bool isAllDay;

  /// `null` = portée nationale.
  final String? cityName;
  final String source;
  final String? sourceUrl;
  final DateTime? lastVerifiedAt;
  final EventReliability reliability;
  final int? priority;
  final List<EventAudienceTag> audienceTags;

  bool get isNational => cityName == null || cityName!.trim().isEmpty;

  DateTime get effectiveEnd => endAt ?? startAt;

  String get categoryLabel => category.labelFr;

  String get reliabilityLabel => reliability.labelFr;
}
