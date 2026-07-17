import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/events/data/event_device_calendar.dart';
import 'package:atlas/features/events/data/local_event_repository.dart';
import 'package:atlas/features/events/data/resilient_event_repository.dart';
import 'package:atlas/features/events/domain/event_repository.dart';
import 'package:atlas/features/events/domain/models/atlas_event.dart';
import 'package:atlas/features/events/presentation/pages/events_calendar_page.dart';
import 'package:atlas/features/events/presentation/widgets/event_reliability_chip.dart';
import 'package:atlas/features/events/presentation/widgets/home_events_sections.dart';

void main() {
  setUp(() {
    EventRepository.resetForTest();
    EditorialRepositoryBootstrap.registerDefaults();
  });

  tearDown(EventRepository.resetForTest);

  testWidgets('HomeEventsSections se masque quand vide', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: const Scaffold(
          body: HomeEventsSections(
            todayEvents: [],
            upcomingEvents: [],
          ),
        ),
      ),
    );

    expect(find.text('Aujourd\'hui au Maroc'), findsNothing);
    expect(find.text('À venir'), findsNothing);
  });

  testWidgets('HomeEventsSections affiche aujourd\'hui et à venir', (
    tester,
  ) async {
    final today = AtlasEvent(
      id: 'today',
      title: 'Événement du jour',
      description: 'Description',
      category: EventCategory.publicHoliday,
      startAt: DateTime(2026, 7, 17),
      isAllDay: true,
      source: 'Test',
      reliability: EventReliability.confirmed,
    );
    final upcoming = AtlasEvent(
      id: 'soon',
      title: 'Bientôt',
      description: 'Description',
      category: EventCategory.publicHoliday,
      startAt: DateTime(2026, 7, 30),
      isAllDay: true,
      source: 'Test',
      reliability: EventReliability.provisional,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: Scaffold(
          body: HomeEventsSections(
            todayEvents: [today],
            upcomingEvents: [upcoming],
          ),
        ),
      ),
    );

    expect(find.text('Aujourd\'hui au Maroc'), findsOneWidget);
    expect(find.text('À venir'), findsOneWidget);
    expect(find.text('Événement du jour'), findsOneWidget);
    expect(find.text('Bientôt'), findsOneWidget);
    expect(find.text('Provisoire'), findsOneWidget);
  });

  testWidgets('agenda liste les fériés locaux', (tester) async {
    EventRepository.registerFactory(
      () => ResilientEventRepository(
        local: LocalEventRepository(
          nowProvider: () => DateTime(2026, 7, 17),
        ),
        fetchRemote: () async => throw Exception('offline'),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: const EventsCalendarPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Agenda Maroc'), findsWidgets);
    expect(find.text('Fête du Trône'), findsOneWidget);
    expect(find.text('Hors ligne'), findsOneWidget);
  });

  testWidgets('chip fiabilité accessible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EventReliabilityChip(
            reliability: EventReliability.estimated,
          ),
        ),
      ),
    );

    expect(find.text('Estimé'), findsOneWidget);
    expect(find.bySemanticsLabel('Statut Estimé'), findsOneWidget);
  });

  test('add to calendar masqué sur web', () {
    expect(EventDeviceCalendar.isSupported, isFalse);
  }, skip: !kIsWeb);

  test('add to calendar supporté hors web', () {
    expect(EventDeviceCalendar.isSupported, isTrue);
  }, skip: kIsWeb);
}
