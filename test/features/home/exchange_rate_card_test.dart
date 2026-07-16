import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/home/domain/models/exchange_rate_snapshot.dart';
import 'package:atlas/features/home/domain/models/home_models.dart';
import 'package:atlas/features/home/presentation/widgets/exchange_rate_card.dart';

void main() {
  testWidgets('affiche le chargement sans taux inventé', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: const Scaffold(
          body: ExchangeRateCard(
            snapshot: ExchangeRateSnapshot.loading(),
          ),
        ),
      ),
    );

    expect(find.text('Chargement du taux…'), findsOneWidget);
    expect(find.textContaining('10.'), findsNothing);
    expect(find.byIcon(Icons.trending_up), findsNothing);
  });

  testWidgets('affiche unavailable sans faux taux', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: const Scaffold(
          body: ExchangeRateCard(
            snapshot: ExchangeRateSnapshot.unavailable(),
          ),
        ),
      ),
    );

    expect(find.text('Taux indisponible'), findsOneWidget);
    expect(find.textContaining('données estimées'), findsNothing);
    expect(find.text('10.78'), findsNothing);
  });

  testWidgets('affiche EUR→MAD, MAD→EUR et dernière mise à jour', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: Scaffold(
          body: ExchangeRateCard(
            snapshot: ExchangeRateSnapshot(
              state: ExchangeRateLoadState.success,
              data: ExchangeRateData(
                fromCurrency: 'EUR',
                toCurrency: 'MAD',
                rate: 10.5,
                sourceLabel: 'Frankfurter · taux de référence',
                referenceDate: '2026-07-10',
                fetchedAt: DateTime.now(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('1 EUR'), findsOneWidget);
    expect(find.text('10.50 MAD'), findsOneWidget);
    expect(find.textContaining('1 MAD ≈'), findsOneWidget);
    expect(find.textContaining('0.0952 EUR'), findsOneWidget);
    expect(find.text('Frankfurter · taux de référence'), findsOneWidget);
    expect(find.textContaining('Mis à jour'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up), findsNothing);
  });
}
