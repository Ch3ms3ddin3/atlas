import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/home/presentation/widgets/home_optional_section.dart';
import 'package:atlas/features/prices/data/price_observation_catalog.dart';
import 'package:atlas/features/prices/data/resilient_price_intelligence_repository.dart';
import 'package:atlas/features/prices/domain/models/price_observation.dart';
import 'package:atlas/features/prices/domain/price_intelligence_repository.dart';
import 'package:atlas/features/prices/presentation/pages/prices_page.dart';
import 'package:atlas/features/prices/presentation/widgets/home_price_highlights_section.dart';
import 'package:atlas/features/prices/presentation/widgets/price_confidence_chip.dart';
import 'package:atlas/features/prices/presentation/widgets/prices_scroll_progress_indicator.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'price_intelligence_fixtures.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PriceIntelligenceRepository.resetForTest();
    EditorialRepositoryBootstrap.registerDefaults();
  });

  tearDown(PriceIntelligenceRepository.resetForTest);

  testWidgets('HomePriceHighlightsSection se masque quand vide', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: const Scaffold(
          body: HomePriceHighlightsSection(
            observations: [],
            onObservationTap: _noop,
          ),
        ),
      ),
    );
    expect(find.text('SP95 Marrakech'), findsNothing);
  });

  testWidgets(
    'highlights Accueil : 2–3 prix city-aware depuis le seed bundlé',
    (tester) async {
      PriceIntelligenceRepository.registerFactory(
        () => ResilientPriceIntelligenceRepository(
          fetchRemote: () async => throw Exception('offline'),
          seedItems: PriceObservationCatalog.asObservations,
        ),
      );

      final repo = PriceIntelligenceRepository();
      await repo.warmUp();
      final highlights = repo.highlights(cityName: 'Marrakech', limit: 3);
      expect(highlights.length, inInclusiveRange(2, 3));
      expect(
        highlights.every((e) => e.isNational || e.cityName == 'Marrakech'),
        isTrue,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: Scaffold(
            body: HomeOptionalSection(
              title: 'Prix à la une',
              isEmpty: highlights.isEmpty,
              child: HomePriceHighlightsSection(
                observations: highlights,
                onObservationTap: _noop,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prix à la une'), findsOneWidget);
      expect(find.text(highlights.first.itemName), findsOneWidget);
    },
  );

  testWidgets('highlights Accueil masqués si aucune observation applicable', (
    tester,
  ) async {
    PriceIntelligenceRepository.registerFactory(
      () => ResilientPriceIntelligenceRepository(
        fetchRemote: () async => const [],
      ),
    );
    final repo = PriceIntelligenceRepository();
    await repo.warmUp();
    final highlights = repo.highlights(cityName: 'Marrakech', limit: 3);
    expect(highlights, isEmpty);

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: Scaffold(
          body: HomeOptionalSection(
            title: 'Prix à la une',
            isEmpty: highlights.isEmpty,
            child: HomePriceHighlightsSection(
              observations: highlights,
              onObservationTap: _noop,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Prix à la une'), findsNothing);
  });

  testWidgets('liste Intelligence affiche les prix vérifiés', (tester) async {
    PriceIntelligenceRepository.registerFactory(
      () => ResilientPriceIntelligenceRepository(
        fetchRemote: () async => PriceIntelligenceFixtures.sample,
        seedItems: PriceIntelligenceFixtures.sample,
      ),
    );

    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final profile = LocalProfileRepository();
    await profile.load();

    await tester.pumpWidget(
      ProfileScope(
        repository: profile,
        child: MaterialApp(
          theme: AtlasTheme.light,
          home: const Scaffold(body: PricesPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prix'), findsWidgets);
    expect(find.text('SP95 Marrakech'), findsOneWidget);
    expect(find.text('Taxi Airport Marrakech'), findsOneWidget);
    expect(find.byType(PricesScrollProgressIndicator), findsOneWidget);
  });

  testWidgets('état vide sans données vérifiées', (tester) async {
    PriceIntelligenceRepository.registerFactory(
      () => ResilientPriceIntelligenceRepository(
        fetchRemote: () async => const [],
      ),
    );

    final profile = LocalProfileRepository();
    await profile.load();

    await tester.pumpWidget(
      ProfileScope(
        repository: profile,
        child: MaterialApp(
          theme: AtlasTheme.light,
          home: const Scaffold(body: PricesPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Aucun prix vérifié'), findsOneWidget);
    expect(find.text('SP95 Marrakech'), findsNothing);
  });

  testWidgets('chip confiance accessible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PriceConfidenceChip(confidence: PriceConfidence.high),
        ),
      ),
    );
    expect(find.text('Confiance élevée'), findsOneWidget);
    expect(find.bySemanticsLabel('Confiance élevée'), findsOneWidget);
  });
}

void _noop(PriceObservation _) {}
