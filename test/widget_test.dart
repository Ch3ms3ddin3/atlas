import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/app/atlas_app.dart';
import 'package:atlas/features/shell/presentation/atlas_bottom_nav.dart';

void main() {
  testWidgets('Atlas démarre sur Accueil avec 5 onglets', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AtlasApp());

    expect(find.text('Accueil'), findsWidgets);
    expect(find.text('Bonjour Chemseddine'), findsOneWidget);
    expect(find.text('Marrakech'), findsOneWidget);
    expect(find.text('Dimanche 12 juillet 2026'), findsOneWidget);
    expect(find.text('Briefing du jour'), findsOneWidget);
    expect(find.text('38°'), findsOneWidget);
    expect(find.text('Asr'), findsWidgets);
    expect(find.text('10.78 MAD'), findsOneWidget);
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
      find.textContaining('Lieux, quartiers et expériences'),
      findsOneWidget,
    );

    await tester.tap(find.text('Démarches'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Guides pas à pas pour vos démarches'),
      findsOneWidget,
    );

    await tester.tap(find.text('Prix'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Coût de la vie et repères utiles'),
      findsOneWidget,
    );

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Vos préférences et votre contexte'),
      findsOneWidget,
    );

    await tester.tap(find.text('Accueil'));
    await tester.pumpAndSettle();

    expect(find.text('Bonjour Chemseddine'), findsOneWidget);
    expect(find.text('Forte chaleur prévue'), findsOneWidget);
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
    expect(find.text('Palais de la Bahia'), findsOneWidget);
    expect(find.text('Urgences'), findsOneWidget);
    expect(find.text('Padel'), findsOneWidget);
    expect(
      find.textContaining('Toutes les données mises à jour'),
      findsOneWidget,
    );
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
}
