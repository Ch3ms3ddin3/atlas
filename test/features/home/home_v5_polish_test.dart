import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/home/data/home_dashboard_catalog.dart';
import 'package:atlas/features/home/data/pour_vous/pour_vous_builder.dart';
import 'package:atlas/features/home/domain/models/home_models.dart';
import 'package:atlas/features/home/presentation/widgets/greeting_header.dart';
import 'package:atlas/features/home/presentation/widgets/pour_vous_section.dart';
import 'package:atlas/features/home/presentation/widgets/quick_actions_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Pour vous shows title, detail and contextual icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: const Scaffold(
          body: PourVousSection(
            recommendations: [
              PourVousRecommendation(
                icon: Icons.park_outlined,
                message:
                    'Jardin Majorelle — réservez tôt si vous souhaitez y aller.',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Pour vous'), findsOneWidget);
    expect(find.text('Jardin Majorelle'), findsOneWidget);
    expect(
      find.text('réservez tôt si vous souhaitez y aller.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.park_outlined), findsOneWidget);
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
            child: QuickActionsGrid(
              actions: HomeDashboardCatalog.quickActions,
            ),
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
}
