import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/prices/data/price_catalog.dart';
import 'package:atlas/features/prices/data/price_mapper.dart';
import 'package:atlas/features/prices/data/price_repository.dart';
import 'package:atlas/features/prices/domain/models/price_models.dart';

void main() {
  group('PriceMapper', () {
    test('filtre par ville', () {
      final guides = PriceMapper.filter(
        const PriceSearchQuery(cityName: 'Casablanca'),
      );

      expect(guides, isNotEmpty);
      expect(
        guides.every((guide) => guide.cityName == 'Casablanca'),
        isTrue,
      );
    });

    test('filtre par catégorie', () {
      final guides = PriceMapper.filter(
        const PriceSearchQuery(
          cityName: 'Marrakech',
          category: PriceCategory.logement,
        ),
      );

      expect(guides.any((guide) => guide.id == 'price-rent-marrakech'), isTrue);
      expect(
        guides.every((guide) => guide.category == PriceCategory.logement),
        isTrue,
      );
    });

    test('recherche par mot-clé', () {
      final guides = PriceMapper.filter(
        const PriceSearchQuery(
          cityName: 'Rabat',
          text: 'taxi',
        ),
      );

      expect(guides.any((guide) => guide.id == 'price-taxi-rabat'), isTrue);
    });

    test('retombe sur Marrakech pour une ville inconnue', () {
      expect(
        PriceMapper.resolveCityName('Fès'),
        'Marrakech',
      );
    });

    test('formate les montants en MAD', () {
      expect(PriceMapper.formatAmount(4500), '4 500 MAD');
      expect(PriceMapper.formatAmount(90), '90 MAD');
    });
  });

  group('PriceRepository', () {
    const repository = PriceRepository();

    test('expose au moins 12 repères au total', () {
      expect(PriceCatalog.guides.length, greaterThanOrEqualTo(12));
    });

    test('retrouve un prix par identifiant', () {
      final guide = repository.findById('price-restaurant-marrakech');

      expect(guide, isNotNull);
      expect(guide!.name, 'Repas au restaurant');
    });

    test('combine recherche textuelle et filtre catégorie', () {
      final guides = repository.search(
        const PriceSearchQuery(
          cityName: 'Casablanca',
          text: 'studio',
          category: PriceCategory.logement,
        ),
      );

      expect(guides.any((guide) => guide.id == 'price-rent-casablanca'), isTrue);
    });

    test('détecte une ville non couverte', () {
      expect(repository.isCityCovered('Tanger'), isFalse);
      expect(repository.isCityCovered('Rabat'), isTrue);
    });
  });
}
