import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/app/atlas_app.dart';
import 'package:atlas/core/datetime/casablanca_date_formatter.dart';
import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/features/home/data/prayer/prayer_mapper.dart';
import 'package:atlas/features/prices/presentation/widgets/price_disclaimer_banner.dart';
import 'package:atlas/features/shell/presentation/atlas_bottom_nav.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    ensurePrayerNotificationCoordinatorForTests();
  });

  testWidgets('Atlas démarre sur Accueil avec 5 onglets', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AtlasApp());

    expect(find.text('—°'), findsOneWidget);
    expect(find.text('Chargement…'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Accueil'), findsWidgets);
    expect(find.text('Bonjour Chemseddine'), findsOneWidget);
    expect(find.text('Marrakech'), findsOneWidget);
    expect(
      find.text(
        CasablancaDateFormatter.formatLongDate(PrayerMapper.casablancaNow()),
      ),
      findsOneWidget,
    );
    expect(find.text('Briefing du jour'), findsOneWidget);
    expect(find.text('Asr'), findsWidgets);
    expect(find.text('1 EUR'), findsOneWidget);
    expect(find.textContaining('MAD'), findsOneWidget);
    expect(find.text('Jour ouvré'), findsOneWidget);

    expect(AtlasBottomNav.destinations, hasLength(5));
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('La navigation bascule entre les onglets', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AtlasApp());

    await tester.tap(find.text('Explorer'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Lieux utiles à Marrakech'),
      findsOneWidget,
    );
    expect(find.text('Jardin Majorelle'), findsWidgets);

    await tester.tap(find.text('Démarches'));
    await tester.pumpAndSettle();

    expect(find.text('Guides pas à pas pour vos démarches au Maroc.'), findsOneWidget);
    expect(find.text('Renouveler la CIN'), findsOneWidget);
    expect(find.text('Carte de séjour'), findsOneWidget);

    await tester.tap(find.text('Prix'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Repères de prix à Marrakech'),
      findsOneWidget,
    );
    expect(find.text('Course de taxi'), findsOneWidget);
    expect(find.text(PriceDisclaimerBanner.text), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Personnalisez Atlas'),
      findsOneWidget,
    );
    expect(find.text('Enregistrer'), findsOneWidget);

    await tester.tap(find.text('Accueil'));
    await tester.pumpAndSettle();

    expect(find.text('Bonjour Chemseddine'), findsOneWidget);
    expect(find.text('Forte chaleur prévue'), findsWidgets);
  });

  testWidgets('Le tableau de bord affiche les sections principales', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AtlasApp());

    expect(find.text('À savoir aujourd\'hui'), findsOneWidget);
    expect(find.text('Actions rapides'), findsOneWidget);
    expect(find.text('Administratif'), findsWidgets);
    expect(find.text('Recommandations'), findsOneWidget);
    expect(find.text('Admission temporaire'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('Jardin Majorelle'), findsOneWidget);
    expect(find.text('Place Jemaa el-Fna'), findsOneWidget);
    expect(find.text('Urgences'), findsOneWidget);
    expect(find.text('Padel'), findsOneWidget);
    expect(
      find.textContaining('Toutes les données mises à jour'),
      findsWidgets,
    );
  });

  testWidgets('Le rappel administratif ouvre le guide CIN', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AtlasApp());
    await tester.pumpAndSettle();

    final reminder = find.text('Renouveler la CIN').first;
    await tester.ensureVisible(reminder);
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

    await tester.pumpWidget(const AtlasApp());
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
    expect(find.textContaining('maps.google.com'), findsOneWidget);
  });

  testWidgets('Un repère de prix ouvre le détail', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AtlasApp());

    await tester.tap(find.text('Prix'));
    await tester.pumpAndSettle();

    final priceItem = find.text('Course de taxi').first;
    await tester.ensureVisible(priceItem);
    await tester.pumpAndSettle();
    await tester.tap(priceItem);
    await tester.pumpAndSettle();

    expect(find.text('Fourchette normale'), findsOneWidget);
    expect(find.text('Ce qui fait varier le prix'), findsOneWidget);

    final alertSection = find.text('Signaux d\'alerte');
    await tester.scrollUntilVisible(
      alertSection,
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(alertSection, findsOneWidget);

    final negotiationSection = find.text('Conseils de négociation');
    await tester.scrollUntilVisible(
      negotiationSection,
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(negotiationSection, findsOneWidget);
    expect(find.text(PriceDisclaimerBanner.text), findsOneWidget);
  });

  testWidgets('Les actions rapides sont tappables', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AtlasApp());

    await tester.ensureVisible(find.text('Urgences'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Urgences'));
    await tester.pumpAndSettle();

    expect(
      find.text('Urgences — bientôt disponible'),
      findsOneWidget,
    );
  });

  testWidgets('Le profil enregistre le prénom et met à jour l\'accueil', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AtlasApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

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

    await tester.tap(find.text('Accueil'));
    await tester.pumpAndSettle();

    expect(find.text('Bonjour Salma'), findsOneWidget);
  });
}
