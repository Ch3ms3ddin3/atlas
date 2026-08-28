import 'package:atlas/core/location/atlas_city_source.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/home/data/daily_insight/daily_insight_builder.dart';
import 'package:atlas/features/home/data/home_dashboard_catalog.dart';
import 'package:atlas/features/home/domain/models/home_models.dart';
import 'package:atlas/features/home/presentation/widgets/daily_insight_section.dart';
import 'package:atlas/features/home/presentation/widgets/greeting_header.dart';
import 'package:atlas/features/home/presentation/widgets/quick_actions_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Bon à savoir shows tip when data is present', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: const Scaffold(
          body: DailyInsightSection(
            data: DailyInsightData(
              icon: Icons.wb_sunny_outlined,
              message:
                  'Chaleur intense — hydratez-vous et privilégiez l\'ombre.',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Bon à savoir'), findsOneWidget);
    expect(find.text('Chaleur intense'), findsOneWidget);
    expect(find.text('hydratez-vous et privilégiez l\'ombre.'), findsOneWidget);
    expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);
  });

  testWidgets('Bon à savoir hides when tip is null', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: const Scaffold(body: DailyInsightSection(data: null)),
      ),
    );

    expect(find.text('Bon à savoir'), findsNothing);
  });

  testWidgets('quick actions keep Démarches fully visible on iPhone width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: QuickActionsGrid(actions: HomeDashboardCatalog.quickActions),
          ),
        ),
      ),
    );

    expect(find.text('Démarches'), findsOneWidget);
    expect(find.text('Explorer'), findsOneWidget);
    expect(find.text('Carte'), findsOneWidget);
    expect(find.text('Prix'), findsOneWidget);

    final demarches = tester.widget<Text>(find.text('Démarches'));
    expect(demarches.maxLines, 1);
    expect(find.textContaining('Démarc…'), findsNothing);
    expect(find.textContaining('Démar…'), findsNothing);
  });

  testWidgets('profile avatar shows first letter of display name', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: Scaffold(
          body: GreetingHeader(
            data: const GreetingData(
              userName: 'Salma',
              city: 'Marrakech',
              dateLabel: 'vendredi 7 août',
            ),
            onProfileTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('S'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsNothing);
  });

  testWidgets('profile avatar falls back to V for Voyageur', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: Scaffold(
          body: GreetingHeader(
            data: const GreetingData(
              userName: 'Voyageur',
              city: 'Marrakech',
              dateLabel: 'vendredi 7 août',
            ),
            onProfileTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('V'), findsOneWidget);
  });

  testWidgets('Accueil auto : horloge appareil, pas Casablanca', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: Scaffold(
          body: GreetingHeader(
            data: const GreetingData(
              userName: 'Voyageur',
              city: '',
              dateLabel: 'vendredi 28 août 2026',
            ),
            citySource: AtlasCitySource.auto,
            clockNow: () => DateTime(2026, 8, 28, 8, 29),
            onProfileTap: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('08:29'), findsOneWidget);
    expect(find.textContaining('07:29'), findsNothing);
    expect(find.text('Marrakech'), findsNothing);
  });
}
