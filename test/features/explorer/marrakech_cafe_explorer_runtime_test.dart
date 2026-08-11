import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/data/place_catalog.dart';
import 'package:atlas/features/explorer/data/place_mapper.dart';
import 'package:atlas/features/explorer/data/resilient_place_repository.dart';
import 'package:atlas/features/explorer/domain/models/place_models.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/explorer/domain/place_repository.dart';
import 'package:atlas/features/explorer/presentation/pages/explorer_page.dart';
import 'package:atlas/features/explorer/presentation/widgets/explorer_empty_state.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_guide_card.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';
import 'package:atlas/features/shell/presentation/shell_navigation_scope.dart';

const _cafeIds = <String>{
  'place-bacha-coffee',
  'place-simple-specialty-coffee',
  'place-cafe-des-epices',
  'place-kartell-kollektiv',
  'place-cafe-clock',
};

const _cafeNames = <String>[
  'Bacha Coffee',
  'Simple Specialty Coffee',
  'Café des Épices',
  'Kartell Kollektiv',
  'Café Clock',
];

const _restaurantIds = <String>{
  'place-al-fassia-gueliz',
  'place-amal-gueliz',
  'place-nomad',
  'place-plus61',
  'place-le-jardin',
  'place-sahbi-sahbi',
  'place-grand-cafe-de-la-poste',
  'place-catanzaro',
  'place-naranj',
  'place-la-trattoria',
  'place-dar-moha',
};

/// Simule Supabase live sans les 5 cafés (vieux seed distant).
List<PlaceGuide> _oldRemoteWithoutCafes() {
  return PlaceCatalog.guides
      .where((place) => !_cafeIds.contains(place.id))
      .toList(growable: false);
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    ensurePrayerNotificationCoordinatorForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaceRepository.resetForTest();
    PlaceBrowseFilters.resetForTest();
  });

  tearDown(() {
    PlaceRepository.resetForTest();
    PlaceBrowseFilters.resetForTest();
  });

  group('Explorer runtime path — Marrakech cafés', () {
    test(
      'PlaceMapper: texte « café » ignore une catégorie Hammam conflictuelle',
      () {
        final places = PlaceMapper.filter(
          const PlaceSearchQuery(
            text: 'café',
            category: PlaceCategory.hammam,
            cityName: 'Marrakech',
            strictCity: true,
          ),
        );
        expect(places.map((p) => p.id).toSet(), _cafeIds);
        expect(
          places.every((p) => p.category == PlaceCategory.cafe),
          isTrue,
        );
      },
    );

    test(
      'PlaceMapper: texte « coffee » renvoie les 5 cafés Marrakech',
      () {
        final places = PlaceMapper.filter(
          const PlaceSearchQuery(
            text: 'coffee',
            cityName: 'Marrakech',
            strictCity: true,
          ),
        );
        expect(places.map((p) => p.id).toSet(), _cafeIds);
      },
    );

    test(
      'PlaceMapper: puce Café seule renvoie les 5 cafés Marrakech',
      () {
        final places = PlaceMapper.filter(
          const PlaceSearchQuery(
            category: PlaceCategory.cafe,
            cityName: 'Marrakech',
            strictCity: true,
          ),
        );
        expect(places.map((p) => p.id).toSet(), _cafeIds);
      },
    );

    test(
      'ResilientPlaceRepository (chemin Explorer): search café après warmUp distant vieux',
      () async {
        late ResilientPlaceRepository repository;
        PlaceRepository.registerFactory(() {
          repository = ResilientPlaceRepository(
            local: LocalPlaceRepository(),
            fetchRemote: () async => _oldRemoteWithoutCafes(),
          );
          return repository;
        });

        final repo = PlaceRepository.instance;
        await repo.warmUp();

        final byText = repo.search(
          const PlaceSearchQuery(
            text: 'café',
            category: PlaceCategory.hammam,
            cityName: 'Marrakech',
            sort: PlaceSort.catalog,
            strictCity: true,
          ),
        );
        final byCategory = repo.search(
          const PlaceSearchQuery(
            text: '',
            category: PlaceCategory.cafe,
            cityName: 'Marrakech',
            sort: PlaceSort.catalog,
            strictCity: true,
          ),
        );
        final restaurants = repo.search(
          const PlaceSearchQuery(
            text: '',
            category: PlaceCategory.restaurant,
            cityName: 'Marrakech',
            sort: PlaceSort.catalog,
            strictCity: true,
          ),
        );

        expect(byText.map((p) => p.id).toSet(), _cafeIds);
        expect(byCategory.map((p) => p.id).toSet(), _cafeIds);
        expect(restaurants.map((p) => p.id).toSet(), _restaurantIds);
        expect(byText.map((p) => p.name), containsAll(_cafeNames));
      },
    );
  });

  group('ExplorerPage widget — Marrakech cafés', () {
    Future<void> pumpExplorer(WidgetTester tester) async {
      late ResilientPlaceRepository repository;
      PlaceRepository.registerFactory(() {
        repository = ResilientPlaceRepository(
          local: LocalPlaceRepository(),
          fetchRemote: () async => _oldRemoteWithoutCafes(),
        );
        return repository;
      });
      await PlaceRepository.instance.warmUp();

      final profileRepository = LocalProfileRepository();
      final favoritesRepository = LocalFavoritesRepository();
      await profileRepository.load();
      await favoritesRepository.load();

      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: ProfileScope(
            repository: profileRepository,
            child: FavoritesScope(
              repository: favoritesRepository,
              child: ShellNavigationScope(
                navigateToTab: (_) {},
                child: const Scaffold(body: ExplorerPage()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'Marrakech + puce Café affiche les 5 cafés',
      (tester) async {
        await pumpExplorer(tester);

        await tester.tap(find.text('Marrakech'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Café').first);
        await tester.pumpAndSettle();

        expect(find.byType(ExplorerEmptyState), findsNothing);
        for (final name in _cafeNames) {
          expect(find.text(name), findsWidgets, reason: name);
        }
        expect(find.byType(PlaceGuideCard), findsNWidgets(5));
      },
    );

    testWidgets(
      'Marrakech + recherche « coffee » affiche les 5 cafés',
      (tester) async {
        await pumpExplorer(tester);

        await tester.tap(find.text('Marrakech'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'coffee');
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pumpAndSettle();

        expect(find.byType(ExplorerEmptyState), findsNothing);
        for (final name in _cafeNames) {
          expect(find.text(name), findsWidgets, reason: name);
        }
      },
    );
  });
}
