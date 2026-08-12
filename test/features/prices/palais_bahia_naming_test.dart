import 'package:atlas/features/explorer/data/place_catalog.dart';
import 'package:atlas/features/prices/data/price_observation_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Palais Bahia est le libellé utilisateur (slug inchangé)', () {
    final place = PlaceCatalog.guides.firstWhere((p) => p.id == 'place-bahia');
    expect(place.id, 'place-bahia');
    expect(place.name, 'Palais Bahia');
    expect(place.name.contains('de la'), isFalse);

    final priceRows = PriceObservationCatalog.entries
        .where((e) => e.slug.startsWith('culture-palais-bahia-'))
        .toList();
    expect(priceRows.length, 2);
    for (final row in priceRows) {
      expect(row.itemName.startsWith('Palais Bahia'), isTrue);
      expect(row.itemName.contains('Palais de la Bahia'), isFalse);
    }
  });
}
