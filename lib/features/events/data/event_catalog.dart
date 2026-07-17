import '../domain/models/atlas_event.dart';

/// Jours fériés civils fixes du Maroc — seuls contenus du catalogue local.
///
/// Sources : calendrier officiel des fêtes nationales (dates grégoriennes fixes).
/// Pas de dates religieuses, festivals, sport ni vacances scolaires ici.
abstract final class EventCatalog {
  static const sourceLabel = 'Calendrier officiel des fêtes nationales';
  static const sourceUrl = 'https://www.maroc.ma/';
  static final lastVerifiedAt = DateTime.utc(2026, 1, 15);

  static const _fixedHolidays = <({int month, int day, String slug, String title, String description})>[
    (
      month: 1,
      day: 1,
      slug: 'jour-de-lan',
      title: 'Jour de l\'an',
      description:
          'Fête nationale — administrations et banques fermées.',
    ),
    (
      month: 1,
      day: 11,
      slug: 'manifeste-independance',
      title: 'Manifeste de l\'indépendance',
      description:
          'Commémoration du Manifeste de l\'indépendance — fête nationale.',
    ),
    (
      month: 1,
      day: 14,
      slug: 'yennayer',
      title: 'Yennayer',
      description:
          'Nouvel An amazigh — fête nationale fixe au 14 janvier.',
    ),
    (
      month: 5,
      day: 1,
      slug: 'fete-du-travail',
      title: 'Fête du travail',
      description:
          'Fête du travail — administrations et banques fermées.',
    ),
    (
      month: 7,
      day: 30,
      slug: 'fete-du-trone',
      title: 'Fête du Trône',
      description:
          'Fête du Trône — fête nationale marocaine.',
    ),
    (
      month: 8,
      day: 14,
      slug: 'oued-ed-dahab',
      title: 'Fête de Oued Ed-Dahab',
      description:
          'Commémoration du retour d\'Oued Ed-Dahab — fête nationale.',
    ),
    (
      month: 8,
      day: 20,
      slug: 'revolution-roi-peuple',
      title: 'Révolution du Roi et du Peuple',
      description:
          'Commémoration de la Révolution du Roi et du Peuple.',
    ),
    (
      month: 8,
      day: 21,
      slug: 'fete-de-la-jeunesse',
      title: 'Fête de la Jeunesse',
      description:
          'Fête de la Jeunesse — fête nationale.',
    ),
    (
      month: 11,
      day: 6,
      slug: 'marche-verte',
      title: 'Marche Verte',
      description:
          'Anniversaire de la Marche Verte — fête nationale.',
    ),
    (
      month: 11,
      day: 18,
      slug: 'fete-independance',
      title: 'Fête de l\'Indépendance',
      description:
          'Fête de l\'Indépendance — fête nationale.',
    ),
  ];

  /// Génère les fériés confirmés pour les années demandées (portée nationale).
  static List<AtlasEvent> fixedPublicHolidaysForYears(Iterable<int> years) {
    final events = <AtlasEvent>[];
    for (final year in years) {
      for (final holiday in _fixedHolidays) {
        final start = DateTime(year, holiday.month, holiday.day);
        events.add(
          AtlasEvent(
            id: '${holiday.slug}-$year',
            title: holiday.title,
            description: holiday.description,
            category: EventCategory.publicHoliday,
            startAt: start,
            endAt: start,
            isAllDay: true,
            cityName: null,
            source: sourceLabel,
            sourceUrl: sourceUrl,
            lastVerifiedAt: lastVerifiedAt,
            reliability: EventReliability.confirmed,
            priority: 10,
            audienceTags: const [
              EventAudienceTag.resident,
              EventAudienceTag.mre,
              EventAudienceTag.visitor,
              EventAudienceTag.expat,
            ],
          ),
        );
      }
    }
    events.sort((a, b) => a.startAt.compareTo(b.startAt));
    return events;
  }

  /// Catalogue local servi immédiatement (année courante + suivante, Casablanca).
  static List<AtlasEvent> localFallback({DateTime? reference}) {
    final now = reference ?? DateTime.now().toUtc().add(const Duration(hours: 1));
    return fixedPublicHolidaysForYears([now.year, now.year + 1]);
  }
}
