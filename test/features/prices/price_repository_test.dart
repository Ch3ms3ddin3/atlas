import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/prices/data/price_catalog.dart';
import 'package:atlas/features/prices/data/price_mapper.dart';
import 'package:atlas/features/prices/data/price_repository.dart';
import 'package:atlas/features/prices/domain/models/price_models.dart';

void main() {
  group('PriceMapper', () {
    test('filtre par ville et inclut les entrées nationales', () {
      final guides = PriceMapper.filter(
        const PriceSearchQuery(cityName: 'Casablanca'),
      );

      expect(guides, isNotEmpty);
      expect(
        guides.every(
          (guide) =>
              guide.cityName == 'Casablanca' ||
              guide.cityName == PriceNationalCity.name,
        ),
        isTrue,
      );
      expect(
        guides.any((guide) => guide.id == 'price-ctm-bus'),
        isTrue,
      );
    });

    test('filtre par catégorie', () {
      final guides = PriceMapper.filter(
        const PriceSearchQuery(
          cityName: 'Marrakech',
          category: PriceCategory.housing,
        ),
      );

      expect(guides.any((guide) => guide.id == 'price-rent-marrakech'), isTrue);
      expect(
        guides.every((guide) => guide.category == PriceCategory.housing),
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

    test('recherche dans les signaux d\'alerte', () {
      final guides = PriceMapper.filter(
        const PriceSearchQuery(
          cityName: 'Marrakech',
          text: 'compteur',
        ),
      );

      expect(guides, isNotEmpty);
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

    test('formate une fourchette de prix', () {
      final guide = PriceCatalog.guides.first;
      expect(PriceMapper.formatRange(guide), '20 – 50 MAD');
    });

    test('formate la date de mise à jour', () {
      final guide = PriceCatalog.guides.first;
      expect(
        PriceMapper.formatLastUpdated(guide.lastUpdatedAt),
        contains('Mis à jour le'),
      );
    });
  });

  group('PriceRepository', () {
    const repository = PriceRepository();

    test('expose au moins 24 repères au total', () {
      expect(PriceCatalog.guides.length, greaterThanOrEqualTo(24));
    });

    test('couvre les six catégories MVP', () {
      final categories = PriceCatalog.guides.map((g) => g.category).toSet();
      expect(categories, contains(PriceCategory.transport));
      expect(categories, contains(PriceCategory.foodAndCafes));
      expect(categories, contains(PriceCategory.groceries));
      expect(categories, contains(PriceCategory.services));
      expect(categories, contains(PriceCategory.tourism));
      expect(categories, contains(PriceCategory.housing));
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
          category: PriceCategory.housing,
        ),
      );

      expect(guides.any((guide) => guide.id == 'price-rent-casablanca'), isTrue);
    });

    test('détecte une ville non couverte', () {
      expect(repository.isCityCovered('Tanger'), isFalse);
      expect(repository.isCityCovered('Rabat'), isTrue);
    });

    test('contient au moins un piège touristique', () {
      expect(
        PriceCatalog.guides.any((guide) => guide.isTouristTrap),
        isTrue,
      );
      expect(
        repository.findById('price-juice-jemaa-marrakech')?.isTouristTrap,
        isTrue,
      );
    });

    test('chaque entrée a des champs éditoriaux obligatoires', () {
      for (final guide in PriceCatalog.guides) {
        expect(guide.priceFactors, isNotEmpty);
        expect(guide.warningSigns, isNotEmpty);
        expect(guide.negotiationTips, isNotEmpty);
        expect(guide.minAmountMad, lessThanOrEqualTo(guide.maxAmountMad));
        expect(
          guide.averageAmountMad,
          inInclusiveRange(guide.minAmountMad, guide.maxAmountMad),
        );
      }
    });
  });
}
