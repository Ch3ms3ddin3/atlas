import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/app/atlas_app.dart';
import 'package:atlas/core/datetime/casablanca_date_formatter.dart';
import 'package:atlas/features/admission_temporaire/data/at_bootstrap.dart';
import 'package:atlas/features/home/data/prayer/prayer_mapper.dart';
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
    expect(find.text('Bonjour, Chemseddine'), findsOneWidget);
    expect(find.text('Marrakech'), findsWidgets);
    expect(
      find.text(
        CasablancaDateFormatter.formatLongDate(PrayerMapper.casablancaNow()),
      ),
      findsOneWidget,
    );
    expect(find.text('Briefing du jour'), findsOneWidget);
    expect(find.text('Mes véhicules au Maroc'), findsOneWidget);
    expect(find.text('Ajouter un véhicule'), findsOneWidget);
    expect(find.text('Météo indisponible'), findsOneWidget);
    expect(find.text('Horaires indisponibles'), findsOneWidget);
    expect(find.text('Taux indisponible'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    expect(find.text('Jour ouvré'), findsOneWidget);

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
      find.textContaining('Lieux utiles à Marrakech'),
      findsOneWidget,
    );
    expect(find.text('Jardin Majorelle'), findsWidgets);

    await tapBottomNav(tester, 'Carte');
    expect(find.text('Carte'), findsWidgets);
    expect(find.text('Favoris'), findsWidgets);

    await tapBottomNav(tester, 'Démarches');

    expect(find.text('Guides pas à pas pour vos démarches au Maroc.'), findsOneWidget);
    expect(find.text('Renouveler la CIN'), findsOneWidget);
    expect(find.text('Carte de séjour'), findsOneWidget);

    await tapBottomNav(tester, 'Prix');

    expect(
      find.textContaining('Prix vérifiés au Maroc'),
      findsOneWidget,
    );
    expect(find.text('SP95 Marrakech'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Taxi Airport Marrakech'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Taxi Airport Marrakech'), findsOneWidget);

    await tapBottomNav(tester, 'Profil');

    expect(
      find.textContaining('Personnalisez Atlas'),
      findsOneWidget,
    );
    expect(find.text('Enregistrer'), findsOneWidget);

    await tapBottomNav(tester, 'Accueil');

    expect(find.text('Bonjour, Chemseddine'), findsOneWidget);
    expect(find.text('Météo indisponible'), findsOneWidget);
    expect(find.text('Forte chaleur prévue'), findsNothing);
  });

  testWidgets('Le tableau de bord affiche les sections principales', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAtlasApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('À savoir aujourd\'hui'), findsOneWidget);
    expect(find.text('À venir'), findsOneWidget);
    expect(find.text('Mes véhicules au Maroc'), findsOneWidget);
    expect(find.text('Ajouter un véhicule'), findsOneWidget);
    expect(find.text('Actions rapides'), findsOneWidget);
    expect(find.text('Lieux'), findsWidgets);
    expect(find.text('Mes favoris'), findsNothing);
    expect(find.text('Recommandations'), findsOneWidget);
    expect(find.text('Démarches utiles'), findsOneWidget);
    expect(find.text('Prix à la une'), findsOneWidget);
    expect(find.text('Voir tout'), findsOneWidget);
    expect(find.textContaining('Admission temporaire'), findsOneWidget);
    expect(find.text('42'), findsNothing);
    expect(find.text('Jardin Majorelle'), findsOneWidget);
    expect(find.text('Place Jemaa el-Fna'), findsOneWidget);
    expect(find.text('SP95 Marrakech'), findsOneWidget);
    expect(find.text('Urgences'), findsNothing);
    expect(find.text('Padel'), findsNothing);
    expect(
      find.textContaining('Toutes les données mises à jour'),
      findsWidgets,
    );
  });

  testWidgets('Une démarche utile ouvre le guide CIN', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAtlasApp(tester);
    await tester.pumpAndSettle();

    final reminder = find.text('Renouveler la CIN').first;
    await tester.scrollUntilVisible(
      reminder,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(reminder);
    await tester.pumpAndSettle();

    expect(find.text('Documents requis'), findsOneWidget);
    expect(find.text('Étapes'), findsOneWidget);
    expect(find.textContaining('cnie.ma'), findsOneWidget);
  });

  testWidgets('Une recommandation ouvre le détail du lieu', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAtlasApp(tester);
    await tester.pumpAndSettle();

    final place = find.text('Jardin Majorelle').first;
    await tester.scrollUntilVisible(
      place,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(place);
    await tester.pumpAndSettle();

    expect(find.text('Conseils pratiques'), findsOneWidget);
    expect(find.text('Meilleur moment'), findsOneWidget);
    expect(find.byTooltip('Signaler un problème'), findsOneWidget);
    expect(find.textContaining('maps.google.com'), findsNothing);
  });

  testWidgets('Un repère de prix ouvre le détail', (
    WidgetTester tester,
  ) async {
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

  testWidgets('Les actions rapides naviguent vers les onglets Atlas', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAtlasApp(tester);
    await tester.pumpAndSettle();

    final lieuxAction = find.text('Lieux').first;
    await tester.ensureVisible(lieuxAction);
    await tester.pumpAndSettle();
    await tester.tap(lieuxAction);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Lieux utiles à Marrakech'),
      findsOneWidget,
    );
    expect(find.text('Urgences — bientôt disponible'), findsNothing);
  });

  testWidgets('Un repère de prix de l\'accueil ouvre le détail', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAtlasApp(tester);
    await tester.pumpAndSettle();

    final priceSection = find.text('Prix à la une');
    await tester.scrollUntilVisible(
      priceSection,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final fuel = find.text('SP95 Marrakech').first;
    await tester.ensureVisible(fuel);
    await tester.pumpAndSettle();
    await tester.tap(fuel);
    await tester.pumpAndSettle();

    expect(find.textContaining('Prix actuel'), findsOneWidget);
    expect(find.text('Fourchette'), findsOneWidget);
    expect(find.text('Vérifié'), findsWidgets);
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

    expect(find.text('Bonjour, Salma'), findsOneWidget);
  });
}
