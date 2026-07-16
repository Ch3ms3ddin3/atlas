import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/admission_temporaire/data/at_bootstrap.dart';
import 'package:atlas/features/admission_temporaire/data/at_calculator.dart';
import 'package:atlas/features/admission_temporaire/data/local_at_repository.dart';
import 'package:atlas/features/admission_temporaire/domain/models/at_vehicle.dart';
import 'package:atlas/features/admission_temporaire/presentation/at_scope.dart';
import 'package:atlas/features/admission_temporaire/presentation/pages/at_tracker_page.dart';
import 'package:atlas/features/admission_temporaire/presentation/widgets/home_vehicles_card.dart';

AtVehicle _sample({int remainingDays = 40}) {
  final now = AtCalculator.calendarDay(AtCalculator.casablancaNow());
  final expiry = now.add(Duration(days: remainingDays));
  final entry = expiry.subtract(const Duration(days: 180));
  final stamp = DateTime.now().toUtc();
  return AtVehicle(
    id: 'vehicle-1',
    label: 'Golf',
    plate: 'AB-123-CD',
    countryCode: 'FR',
    countryLabel: 'France',
    type: AtVehicleType.car,
    entryDate: entry,
    expiryDate: expiry,
    durationDays: 180,
    createdAt: stamp,
    updatedAt: stamp,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetAtBootstrapForTests();
  });

  tearDown(resetAtBootstrapForTests);

  testWidgets('carte Home vide propose d\'ajouter un véhicule', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: Scaffold(
          body: HomeVehiclesCard(
            vehicle: null,
            onAddTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Ajouter un véhicule'), findsOneWidget);
    expect(find.text('Suivi local'), findsOneWidget);
  });

  testWidgets('carte Home affiche le countdown du véhicule urgent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: Scaffold(
          body: HomeVehiclesCard(vehicle: _sample(remainingDays: 12)),
        ),
      ),
    );

    expect(find.text('Golf'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('jours restants'), findsOneWidget);
    expect(find.text('À surveiller'), findsOneWidget);
  });

  testWidgets('tracker vide et ajout via formulaire', (tester) async {
    final repository = LocalAtRepository();
    await repository.load();
    ensureAtRepositoryForTests(repository: repository);

    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: AtScope(
          repository: repository,
          child: const AtTrackerPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucun véhicule suivi'), findsOneWidget);

    await tester.tap(find.text('Ajouter un véhicule').first);
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Berline');
    await tester.enterText(fields.at(1), 'ZZ-999-AA');

    final save = find.text('Enregistrer');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    // Dialog rappels — décliner
    expect(find.text('Activer les rappels ?'), findsOneWidget);
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();

    expect(repository.activeVehicles, hasLength(1));
    expect(find.text('Berline'), findsWidgets);
    expect(repository.notificationPromptShown, isTrue);
    expect(repository.notificationsEnabled, isFalse);
  });
}
