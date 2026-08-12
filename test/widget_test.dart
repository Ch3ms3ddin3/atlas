import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/app/atlas_app.dart';
import 'package:atlas/features/admission_temporaire/data/at_bootstrap.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/map/presentation/widgets/atlas_flutter_map_view.dart';
import 'package:atlas/features/prices/domain/price_intelligence_repository.dart';
import 'package:atlas/features/shell/presentation/atlas_bottom_nav.dart';

import 'features/onboarding/onboarding_test_helpers.dart';
import 'features/prices/price_intelligence_test_helpers.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    seedCompletedOnboarding();
    EditorialRepositoryBootstrap.registerDefaults();
    registerPriceIntelligenceFixtures();
    ensurePrayerNotificationCoordinatorForTests();
    ensureAtRepositoryForTests();
    AtlasFlutterMapView.useSilentTiles = true;
  });

  setUp(() {
    seedCompletedOnboarding();
    EditorialRepositoryBootstrap.registerDefaults();
    registerPriceIntelligenceFixtures();
    resetAtBootstrapForTests();
    ensureAtRepositoryForTests();
    PlaceBrowseFilters.resetForTest();
    AtlasFlutterMapView.useSilentTiles = true;
  });

  tearDown(() {
    PriceIntelligenceRepository.resetForTest();
    PlaceBrowseFilters.resetForTest();
  });

  Future<void> tapBottomNav(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AtlasBottomNav),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpAtlasApp(WidgetTester tester) async {
    await tester.pumpWidget(const AtlasApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('Atlas démarre sur Accueil avec 6 onglets', (
    WidgetTester tester,
  ) async {
    await pumpAtlasApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('Accueil'), findsWidgets);
    expect(find.text('Bonjour Voyageur 👋'), findsOneWidget);
    expect(find.text('Marrakech'), findsWidgets);
    expect(find.textContaining('Aujourd\'hui à Marrakech'), findsOneWidget);
    expect(find.text('Actions rapides'), findsNothing);
    expect(find.text('Utile maintenant'), findsWidgets);
    expect(find.text('Pour vous'), findsNothing);
    expect(find.textContaining('Circulation'), findsNothing);
    expect(find.text('Météo indisponible'), findsWidgets);
    expect(find.text('Horaires indisponibles'), findsWidgets);
    expect(find.text('Taux indisponible'), findsWidgets);
    expect(find.text('Briefing du jour'), findsNothing);
    expect(find.text('Mes véhicules au Maroc'), findsNothing);

    expect(AtlasBottomNav.destinations, hasLength(6));
    expect(find.byType(AtlasBottomNav), findsOneWidget);
  });

  testWidgets('La navigation bascule entre les onglets', (
    WidgetTester tester,
  ) async {
    await pumpAtlasApp(tester);
    await tester.pumpAndSettle();

    await tapBottomNav(tester, 'Explorer');

    expect(
      find.textContaining('Sélection Atlas pour Marrakech'),
      findsOneWidget,
    );
    expect(find.text('Place Jemaa el-Fna'), findsWidgets);

    await tapBottomNav(tester, 'Carte');
    expect(find.text('Carte'), findsWidgets);
    expect(find.text('Favoris'), findsWidgets);

    await tapBottomNav(tester, 'Démarches');

    expect(
      find.text('Guides pas à pas pour vos démarches au Maroc.'),
      findsOneWidget,
    );
    expect(find.text('Renouveler la CIN'), findsOneWidget);
    expect(find.text('Carte de séjour'), findsOneWidget);

    await tapBottomNav(tester, 'Prix');

    expect(find.textContaining('Tarifs vérifiés'), findsOneWidget);

    await tapBottomNav(tester, 'Profil');

    expect(find.textContaining('Identité, synchronisation'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);

    await tapBottomNav(tester, 'Accueil');

    expect(find.text('Bonjour Voyageur 👋'), findsOneWidget);
    expect(find.text('Météo indisponible'), findsWidgets);
    expect(find.text('Forte chaleur prévue'), findsNothing);
  });

  testWidgets('Le tableau de bord V5 affiche les sections principales', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAtlasApp(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('Aujourd\'hui à Marrakech'), findsOneWidget);
    expect(find.text('Actions rapides'), findsNothing);
    expect(find.text('Utile maintenant'), findsWidgets);
    expect(find.text('Prix'), findsWidgets);
    expect(find.text('Pour vous'), findsNothing);
    expect(find.textContaining('Circulation'), findsNothing);
    expect(find.text('il y a 5 min'), findsNothing);
    expect(find.text('Mes favoris'), findsNothing);
    expect(find.text('Démarches utiles'), findsNothing);
  });

  testWidgets('Un repère de prix ouvre le détail', (WidgetTester tester) async {
    await pumpAtlasApp(tester);
    await tester.pumpAndSettle();

    await tapBottomNav(tester, 'Prix');

    final priceItem = find.text('SP95 Marrakech').first;
    await tester.ensureVisible(priceItem);
    await tester.pumpAndSettle();
    await tester.tap(priceItem);
    await tester.pumpAndSettle();

    expect(find.textContaining('Prix actuel'), findsOneWidget);
    expect(find.text('Fourchette'), findsOneWidget);
    expect(find.text('Minimum'), findsOneWidget);
    expect(find.text('Moyenne'), findsOneWidget);
    expect(find.text('Maximum'), findsOneWidget);
    expect(find.textContaining('Source :'), findsOneWidget);
    expect(find.text('Vérifié'), findsWidgets);
    expect(find.text('Confiance élevée'), findsWidgets);
  });

  testWidgets('Utile maintenant ouvre la carte depuis Accueil', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAtlasApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('Utile maintenant'), findsOneWidget);
    final mapAction = find.text('Ouvrir la carte près de moi');
    await tester.ensureVisible(mapAction);
    await tester.pumpAndSettle();
    await tester.tap(mapAction);
    await tester.pumpAndSettle();

    expect(find.text('Favoris'), findsWidgets);
  });

  testWidgets('Le profil enregistre le prénom et met à jour l\'accueil', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAtlasApp(tester);
    await tester.pumpAndSettle();

    await tapBottomNav(tester, 'Profil');

    await tester.enterText(find.byType(TextField).first, 'Salma');

    final saveButton = find.text('Enregistrer');
    await tester.scrollUntilVisible(
      saveButton,
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Profil enregistré'), findsOneWidget);

    await tapBottomNav(tester, 'Accueil');

    expect(find.text('Bonjour Salma 👋'), findsOneWidget);
  });
}
