import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/design_system/widgets/atlas_skeleton.dart';
import 'package:atlas/features/home/domain/models/home_models.dart';
import 'package:atlas/features/home/domain/models/weather_snapshot.dart';
import 'package:atlas/features/home/presentation/widgets/weather_card.dart';

void main() {
  testWidgets('affiche le chargement sans température inventée', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: const Scaffold(
          body: WeatherCard(
            snapshot: WeatherSnapshot.loading(),
          ),
        ),
      ),
    );

    expect(find.byType(AtlasSkeleton), findsWidgets);
    expect(find.textContaining('°'), findsNothing);
    expect(find.text('38°'), findsNothing);
  });

  testWidgets('affiche unavailable sans fausse météo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: const Scaffold(
          body: WeatherCard(
            snapshot: WeatherSnapshot.unavailable(),
          ),
        ),
      ),
    );

    expect(find.text('Météo indisponible'), findsOneWidget);
    expect(find.textContaining('données estimées'), findsNothing);
    expect(find.textContaining('38°'), findsNothing);
  });

  testWidgets('affiche succès avec métriques optionnelles et horodatage', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: Scaffold(
          body: WeatherCard(
            snapshot: WeatherSnapshot(
              state: WeatherLoadState.success,
              data: WeatherData(
                temperature: 36,
                feelsLike: 40,
                condition: 'Ciel dégagé',
                icon: Icons.wb_sunny_outlined,
                weatherCode: 0,
                fetchedAt: DateTime.now(),
                windKmh: 12,
                uvIndex: 8,
                rainProbabilityPercent: 20,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('36°'), findsOneWidget);
    expect(find.text('Ciel dégagé'), findsOneWidget);
    expect(find.text('Ressenti 40°'), findsOneWidget);
    expect(find.text('12 km/h'), findsOneWidget);
    expect(find.text('UV 8'), findsOneWidget);
    expect(find.text('Pluie 20%'), findsOneWidget);
    expect(find.text('Open-Meteo'), findsOneWidget);
    expect(find.textContaining('Mis à jour'), findsOneWidget);
  });

  testWidgets('masque les métriques optionnelles absentes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: Scaffold(
          body: WeatherCard(
            snapshot: WeatherSnapshot(
              state: WeatherLoadState.stale,
              data: WeatherData(
                temperature: 24,
                feelsLike: 24,
                condition: 'Peu nuageux',
                icon: Icons.wb_sunny_outlined,
                weatherCode: 1,
                fetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('24°'), findsOneWidget);
    expect(find.textContaining('km/h'), findsNothing);
    expect(find.textContaining('UV'), findsNothing);
    expect(find.textContaining('Pluie'), findsNothing);
    expect(find.text('Météo enregistrée'), findsOneWidget);
  });
}
