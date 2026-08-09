import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/explorer/data/place_catalog.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_display_helpers.dart';

void main() {
  test('visitDuration dérive des conseils pratiques ou de la catégorie', () {
    final majorelle = PlaceCatalog.guides.first;
    expect(PlaceDisplayHelpers.visitDuration(majorelle), '1h30');
  });

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
}
