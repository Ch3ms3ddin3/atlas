import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/core/location/atlas_city_source.dart';
import 'package:atlas/core/location/location_repository.dart';
import 'package:atlas/core/location/morocco_cities.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/prices/data/price_observation_catalog.dart';
import 'package:atlas/features/prices/data/price_observation_query.dart';
import 'package:atlas/features/prices/data/resilient_price_intelligence_repository.dart';
import 'package:atlas/features/prices/domain/models/price_observation.dart';
import 'package:atlas/features/prices/domain/price_intelligence_repository.dart';
import 'package:atlas/features/prices/presentation/pages/prices_page.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/data/profile_preferences_store.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PriceIntelligenceRepository.resetForTest();
    EditorialRepositoryBootstrap.registerDefaults();
  });

  tearDown(PriceIntelligenceRepository.resetForTest);

  group('Preferred city honesty (Prix)', () {
    test('Marrakech → Fès persiste en local (cold restart)', () async {
      SharedPreferences.setMockInitialValues({});
      const store = ProfilePreferencesStore();
      final repository = LocalProfileRepository(store: store);
      await repository.load();

      final saved = await repository.save(
        repository.profile.copyWith(preferredCity: 'Fès'),
      );
      expect(saved, isTrue);
      expect(repository.profile.preferredCity, 'Fès');

      final reloaded = LocalProfileRepository(store: store);
      await reloaded.load();
      expect(reloaded.profile.preferredCity, 'Fès');
    });

    test(
      'LocationRepository ne force pas Marrakech si préférée = Fès',
      () async {
        final location = await LocationRepository().resolveLocation(
          preferredCityName: 'Fès',
          citySource: AtlasCitySource.manual,
        );
        expect(location.cityName, 'Fès');
        expect(location.latitude, MoroccoCities.fes.latitude);
        expect(location.isFromGps, isFalse);
      },
    );

    test('Fès : aucune ligne locale inventée, nationaux applicables', () {
      final source = PriceObservationCatalog.asObservations;
      final forFes = PriceObservationQuery.filter(
        const PriceIntelligenceQuery(cityName: 'Fès'),
        source: source,
      );

      expect(
        forFes.any((e) => e.cityName == 'Fès'),
        isFalse,
        reason: 'Ne pas inventer de tarifs Fès',
      );
      expect(forFes, isNotEmpty, reason: 'Nationaux doivent rester visibles');
      expect(forFes.every((e) => e.isNational || e.cityName == 'Fès'), isTrue);
      expect(forFes.any((e) => e.isNational), isTrue);
      expect(
        forFes.any((e) => e.cityName == 'Marrakech'),
        isFalse,
        reason: 'Pas de repli silencieux vers Marrakech',
      );
    });

    testWidgets('PricesPage suit la ville préférée Fès sans muter le profil', (
      tester,
    ) async {
      PriceIntelligenceRepository.registerFactory(
        () => ResilientPriceIntelligenceRepository(
          fetchRemote: () async => PriceObservationCatalog.asObservations,
          seedItems: PriceObservationCatalog.asObservations,
        ),
      );

      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final profile = LocalProfileRepository();
      await profile.load();
      await profile.save(profile.profile.copyWith(preferredCity: 'Fès'));
      expect(profile.profile.preferredCity, 'Fès');

      await tester.pumpWidget(
        ProfileScope(
          repository: profile,
          child: MaterialApp(
            theme: AtlasTheme.light,
            home: const Scaffold(body: PricesPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fès'), findsWidgets);
      expect(
        find.textContaining('Pas encore de tarifs vérifiés pour Fès'),
        findsNothing,
        reason: 'Les forfaits nationaux applicables doivent apparaître',
      );

      // Browse another data city — must not rewrite preferred city.
      await tester.tap(find.text('Marrakech').first);
      await tester.pumpAndSettle();
      expect(profile.profile.preferredCity, 'Fès');

      // Profile change must win over temporary Prix filter.
      await profile.save(profile.profile.copyWith(preferredCity: 'Fès'));
      await tester.pumpAndSettle();
      expect(profile.profile.preferredCity, 'Fès');
      expect(find.text('Fès'), findsWidgets);
    });

    testWidgets(
      'changement Marrakech → Fès dans le profil se reflète dans Prix',
      (tester) async {
        PriceIntelligenceRepository.registerFactory(
          () => ResilientPriceIntelligenceRepository(
            fetchRemote: () async => PriceObservationCatalog.asObservations,
            seedItems: PriceObservationCatalog.asObservations,
          ),
        );

        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final profile = LocalProfileRepository();
        await profile.load();
        expect(profile.profile.preferredCity, 'Marrakech');

        await tester.pumpWidget(
          ProfileScope(
            repository: profile,
            child: MaterialApp(
              theme: AtlasTheme.light,
              home: const Scaffold(body: PricesPage()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await profile.save(profile.profile.copyWith(preferredCity: 'Fès'));
        await tester.pumpAndSettle();

        expect(profile.profile.preferredCity, 'Fès');
        expect(find.text('Fès'), findsWidgets);
        expect(find.textContaining('Tarifs vérifiés pour Fès'), findsOneWidget);
      },
    );
  });
}
