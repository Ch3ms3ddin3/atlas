import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/events/data/event_catalog.dart';
import 'package:atlas/features/events/data/event_query.dart';
import 'package:atlas/features/events/data/event_record_mapper.dart';
import 'package:atlas/features/events/data/local_event_repository.dart';
import 'package:atlas/features/events/data/resilient_event_repository.dart';
import 'package:atlas/features/events/domain/event_repository.dart';
import 'package:atlas/features/events/domain/models/atlas_event.dart';

void main() {
  group('EventCatalog', () {
    test('ne contient que des fériés civils confirmés', () {
      final events = EventCatalog.fixedPublicHolidaysForYears([2026]);
      expect(events, isNotEmpty);
      for (final event in events) {
        expect(event.category, EventCategory.publicHoliday);
        expect(event.reliability, EventReliability.confirmed);
        expect(event.source, isNotEmpty);
        expect(event.isNational, isTrue);
        expect(event.category, isNot(EventCategory.religious));
        expect(event.category, isNot(EventCategory.culturalFestival));
      }
      expect(events.any((e) => e.title == 'Fête du Trône'), isTrue);
    });
  });

  group('EventQuery', () {
    final source = EventCatalog.fixedPublicHolidaysForYears([2026]);

    test('today et upcoming selon la date', () {
      final today = EventQuery.today(
        source: source,
        now: DateTime(2026, 7, 30),
      );
      expect(today, hasLength(1));
      expect(today.first.title, 'Fête du Trône');

      final upcoming = EventQuery.upcoming(
        source: source,
        now: DateTime(2026, 7, 17),
        limit: 3,
      );
      expect(upcoming.first.title, 'Fête du Trône');
      expect(upcoming.length, lessThanOrEqualTo(3));
    });

    test('inclut les événements nationaux pour une ville', () {
      final filtered = EventQuery.filter(
        const EventSearchQuery(cityName: 'Marrakech'),
        source: source,
      );
      expect(filtered, isNotEmpty);
      expect(filtered.every((e) => e.isNational), isTrue);
    });
  });

  group('EventRecordMapper', () {
    test('mappe une ligne Supabase valide', () {
      final event = EventRecordMapper.fromRow({
        'slug': 'fete-du-trone-2026',
        'title': 'Fête du Trône',
        'description': 'Fête nationale',
        'category': 'publicHoliday',
        'start_at': '2026-07-30',
        'end_at': '2026-07-30',
        'is_all_day': true,
        'city_name': null,
        'source': 'Calendrier officiel',
        'source_url': 'https://www.maroc.ma/',
        'last_verified_at': '2026-01-15T00:00:00Z',
        'reliability': 'confirmed',
        'priority': 10,
        'audience_tags': ['resident', 'mre'],
      });

      expect(event.id, 'fete-du-trone-2026');
      expect(event.reliability, EventReliability.confirmed);
      expect(event.audienceTags, contains(EventAudienceTag.mre));
    });

    test('préserve provisional et estimated', () {
      final provisional = EventRecordMapper.fromRow({
        'slug': 'aid-provisoire',
        'title': 'Aïd',
        'description': 'Date provisoire',
        'category': 'religious',
        'start_at': '2026-03-20',
        'source': 'Éditorial Atlas',
        'reliability': 'provisional',
      });
      expect(provisional.reliability, EventReliability.provisional);
      expect(provisional.reliabilityLabel, 'Provisoire');

      final estimated = EventRecordMapper.fromRow({
        'slug': 'aid-estime',
        'title': 'Aïd',
        'description': 'Date estimée',
        'category': 'religious',
        'start_at': '2026-03-20',
        'source': 'Éditorial Atlas',
        'reliability': 'estimated',
      });
      expect(estimated.reliability, EventReliability.estimated);
      expect(estimated.reliabilityLabel, isNot('Confirmé'));
    });
  });

  group('ResilientEventRepository', () {
    test('sert le local avant warmUp', () {
      final repository = ResilientEventRepository(
        local: LocalEventRepository(
          nowProvider: () => DateTime(2026, 7, 17),
        ),
        fetchRemote: () async => throw Exception('offline'),
      );

      expect(repository.getAll(), isNotEmpty);
      expect(
        repository.upcoming(now: DateTime(2026, 7, 17)).first.title,
        'Fête du Trône',
      );
    });

    test('retombe en error sur le local si le distant échoue', () async {
      final repository = ResilientEventRepository(
        local: LocalEventRepository(
          nowProvider: () => DateTime(2026, 7, 17),
        ),
        fetchRemote: () async => throw Exception('network'),
      );

      await repository.warmUp();
      expect(repository.loadState.name, 'error');
      expect(repository.getAll(), isNotEmpty);
    });

    test('utilise le distant quand le fetch réussit', () async {
      final remote = [
        AtlasEvent(
          id: 'city-fest',
          title: 'Festival sourcé',
          description: 'Événement éditorial',
          category: EventCategory.culturalFestival,
          startAt: DateTime(2026, 8, 1),
          isAllDay: true,
          cityName: 'Marrakech',
          source: 'Office du tourisme',
          sourceUrl: 'https://example.com',
          lastVerifiedAt: DateTime.utc(2026, 6, 1),
          reliability: EventReliability.confirmed,
        ),
      ];

      final repository = ResilientEventRepository(
        local: LocalEventRepository(
          nowProvider: () => DateTime(2026, 7, 17),
        ),
        fetchRemote: () async => remote,
      );

      await repository.warmUp();
      expect(repository.loadState.name, 'success');
      expect(repository.findById('city-fest')?.title, 'Festival sourcé');
    });
  });
}
