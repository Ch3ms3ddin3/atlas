import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/explorer/data/place_catalog.dart';
import 'package:atlas/features/explorer/domain/models/place_models.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_display_helpers.dart';

void main() {
  test(
    'visitDuration derives from practical tips only — no category defaults',
    () {
      final bahia = PlaceCatalog.guides.firstWhere(
        (p) => p.id == 'place-bahia',
      );
      expect(
        PlaceDisplayHelpers.visitDuration(bahia),
        isNull,
        reason: 'Bahia V1 tip has no prévoyez/comptez duration',
      );

      final ysl = PlaceCatalog.guides.firstWhere(
        (p) => p.id == 'place-ysl-museum',
      );
      expect(
        PlaceDisplayHelpers.visitDuration(ysl),
        isNull,
        reason: 'YSL V1 tip has no prévoyez/comptez duration',
      );
      final majorelle = PlaceCatalog.guides.firstWhere(
        (p) => p.id == 'place-majorelle',
      );
      expect(
        PlaceDisplayHelpers.visitDuration(majorelle),
        isNull,
        reason:
            'Majorelle tips lack prévoyez/comptez — must not invent duration',
      );

      final jemaa = PlaceCatalog.guides.firstWhere(
        (p) => p.id == 'place-jemaa-el-fna',
      );
      expect(PlaceDisplayHelpers.visitDuration(jemaa), isNull);
    },
  );

  test('neighborhoodLabel returns editorial quartier, not a distance', () {
    final majorelle = PlaceCatalog.guides.first;
    expect(PlaceDisplayHelpers.neighborhoodLabel(majorelle), 'Gueliz');
    expect(
      PlaceDisplayHelpers.neighborhoodLabel(majorelle),
      isNot(contains('km')),
    );
    expect(
      PlaceDisplayHelpers.neighborhoodLabel(majorelle),
      isNot(contains('min')),
    );
  });

  test('visitDuration null for place without tips', () {
    const place = PlaceGuide(
      id: 'place-x',
      name: 'X',
      cityName: 'Marrakech',
      category: PlaceCategory.monument,
      categoryLabel: 'Monument',
      neighborhood: 'Médina',
      priceLevel: '€',
      isEditorsPick: false,
      imageColor: Color(0xFF000000),
      summary: 'S',
      practicalTips: [],
    );
    expect(PlaceDisplayHelpers.visitDuration(place), isNull);
  });
}
