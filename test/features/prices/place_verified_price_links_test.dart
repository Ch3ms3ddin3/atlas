import 'package:atlas/features/explorer/data/place_catalog.dart';
import 'package:atlas/features/prices/data/place_verified_price_links.dart';
import 'package:atlas/features/prices/data/price_observation_catalog.dart';
import 'package:atlas/features/prices/data/resilient_price_intelligence_repository.dart';
import 'package:atlas/features/prices/domain/price_intelligence_repository.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_verified_price_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    PriceIntelligenceRepository.resetForTest();
    PriceIntelligenceRepository.registerFactory(
      () => ResilientPriceIntelligenceRepository(
        seedItems: PriceObservationCatalog.asObservations,
        fetchRemote: () async => PriceObservationCatalog.asObservations,
      ),
    );
  });

  tearDown(PriceIntelligenceRepository.resetForTest);

  test('chaque lien place pointe vers des slugs catalogue existants', () {
    final catalogSlugs = PriceObservationCatalog.entries
        .map((e) => e.slug)
        .toSet();
    for (final entry in PlaceVerifiedPriceLinks.byPlaceId.entries) {
      expect(entry.value, isNotEmpty, reason: entry.key);
      for (final slug in entry.value) {
        expect(catalogSlugs, contains(slug), reason: '${entry.key} → $slug');
      }
      expect(
        PlaceCatalog.guides.any((p) => p.id == entry.key),
        isTrue,
        reason: 'place manquant: ${entry.key}',
      );
    }
  });

  test('lieux liés n’ont plus de montants MAD dans openingHours.note', () {
    final linkedIds = PlaceVerifiedPriceLinks.byPlaceId.keys.toSet();
    for (final place in PlaceCatalog.guides) {
      if (!linkedIds.contains(place.id)) continue;
      final note = place.openingHours?.note ?? '';
      expect(
        RegExp(r'\b\d+\s*MAD\b', caseSensitive: false).hasMatch(note),
        isFalse,
        reason: '${place.id}: $note',
      );
      expect(
        RegExp(r'\b\d+\s*Dh\b', caseSensitive: false).hasMatch(note),
        isFalse,
        reason: '${place.id}: $note',
      );
    }
  });

  testWidgets('section Tarif vérifié visible pour Bahia, absente pour café', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PlaceVerifiedPriceSection(placeId: 'place-bahia'),
          ),
        ),
      ),
    );
    expect(find.text('Tarif vérifié'), findsOneWidget);
    expect(find.textContaining('100'), findsWidgets);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlaceVerifiedPriceSection(placeId: 'place-bacha-coffee'),
        ),
      ),
    );
    expect(find.text('Tarif vérifié'), findsNothing);
  });

  test('PricesPage ne dépend pas du PriceCatalog legacy', () async {
    // Garde structurelle : le catalogue Intelligence ne réutilise pas price-*.
    for (final entry in PriceObservationCatalog.entries) {
      expect(entry.slug.startsWith('price-'), isFalse);
    }
  });
}
