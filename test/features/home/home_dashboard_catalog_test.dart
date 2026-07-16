import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/home/data/home_dashboard_catalog.dart';
import 'package:atlas/features/prices/data/price_catalog.dart';
import 'package:atlas/features/prices/domain/models/price_models.dart';
import 'package:atlas/features/procedures/data/procedure_catalog.dart';

void main() {
  group('HomeDashboardCatalog', () {
    test('expose quatre actions de navigation Atlas', () {
      expect(HomeDashboardCatalog.quickActions, hasLength(4));
      expect(
        HomeDashboardCatalog.quickActions.map((action) => action.id),
        ['explorer', 'procedures', 'prices', 'profile'],
      );
    });

    test('résout les démarches curatées depuis le catalogue', () {
      final guides = HomeDashboardCatalog.resolveCuratedProcedures(
        () => ProcedureCatalog.guides,
      );

      expect(guides.map((guide) => guide.id), [
        'cin-renewal',
        'residence-card',
        'admission-temporaire',
      ]);
    });

    test('ignore les démarches curatées absentes', () {
      final guides = HomeDashboardCatalog.resolveCuratedProcedures(
        () => const [],
      );

      expect(guides, isEmpty);
    });

    test('sélectionne des repères de prix utiles par catégorie', () {
      final cityGuides = PriceCatalog.guides
          .where(
            (guide) =>
                guide.cityName == 'Marrakech' ||
                guide.cityName == PriceNationalCity.name,
          )
          .toList();

      final picked = HomeDashboardCatalog.pickUsefulPriceIndicators(
        cityGuides,
        limit: 4,
      );

      expect(picked, isNotEmpty);
      expect(picked.length, lessThanOrEqualTo(4));
      expect(picked.first.category, PriceCategory.transport);
      expect(
        picked.map((guide) => guide.id).toSet().length,
        picked.length,
      );
    });

    test('retourne une liste vide sans prix disponibles', () {
      expect(
        HomeDashboardCatalog.pickUsefulPriceIndicators(const []),
        isEmpty,
      );
    });
  });
}
