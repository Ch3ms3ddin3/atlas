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

const _restaurantNames = <String>[
  'Al Fassia Guéliz',
  'Restaurant Amal Guéliz',
  'Nomad',
  'Plus61',
  'Le Jardin',
  'Sahbi Sahbi',
  'Le Grand Café de la Poste',
  'Catanzaro',
  'Naranj',
  'La Trattoria',
  'Dar Moha',
];

/// Simule Supabase live sans les restaurants Marrakech (vieux seed distant).
List<PlaceGuide> _oldRemoteWithoutRestaurants() {
  return PlaceCatalog.guides
      .where((place) => !_restaurantIds.contains(place.id))
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

  group('Explorer runtime path — Marrakech restaurants', () {
    test(
      'PlaceMapper: texte « restaurant » ignore une catégorie Hammam conflictuelle',
      () {
        final places = PlaceMapper.filter(
          const PlaceSearchQuery(
            text: 'restaurant',
            category: PlaceCategory.hammam,
            cityName: 'Marrakech',
            strictCity: true,
          ),
        );
        expect(places.map((p) => p.id).toSet(), _restaurantIds);
        expect(
          places.every((p) => p.category == PlaceCategory.restaurant),
          isTrue,
        );
      },
    );

    test(
      'PlaceMapper: puce Restaurant seule renvoie les 11 restaurants Marrakech',
      () {
        final places = PlaceMapper.filter(
          const PlaceSearchQuery(
            category: PlaceCategory.restaurant,
            cityName: 'Marrakech',
            strictCity: true,
          ),
        );
        expect(places.map((p) => p.id).toSet(), _restaurantIds);
        expect(places, hasLength(11));
      },
    );

    test(
      'ResilientPlaceRepository (chemin Explorer): search restaurant après warmUp distant vieux',
      () async {
        late ResilientPlaceRepository repository;
        PlaceRepository.registerFactory(() {
          repository = ResilientPlaceRepository(
            local: LocalPlaceRepository(),
            fetchRemote: () async => _oldRemoteWithoutRestaurants(),
          );
          return repository;
        });

        final repo = PlaceRepository.instance;
        await repo.warmUp();

        final byText = repo.search(
          const PlaceSearchQuery(
            text: 'restaurant',
            category: PlaceCategory.hammam,
            cityName: 'Marrakech',
            sort: PlaceSort.catalog,
            strictCity: true,
          ),
        );
        final byCategory = repo.search(
          const PlaceSearchQuery(
            text: '',
            category: PlaceCategory.restaurant,
            cityName: 'Marrakech',
            sort: PlaceSort.catalog,
            strictCity: true,
          ),
        );

        expect(byText.map((p) => p.id).toSet(), _restaurantIds);
        expect(byCategory.map((p) => p.id).toSet(), _restaurantIds);
        expect(byText.map((p) => p.name), containsAll(_restaurantNames));
        expect(
          byCategory.where((p) => p.isEditorsPick).map((p) => p.id).toSet(),
          {'place-al-fassia-gueliz', 'place-amal-gueliz', 'place-nomad'},
        );
      },
    );
  });

  group('ExplorerPage widget — Marrakech restaurants', () {
    Future<void> pumpExplorer(WidgetTester tester) async {
      PlaceRepository.registerFactory(() {
        return ResilientPlaceRepository(
          local: LocalPlaceRepository(),
          fetchRemote: () async => _oldRemoteWithoutRestaurants(),
        );
      });
      await PlaceRepository.instance.warmUp();

      final profileRepository = LocalProfileRepository();
      final favoritesRepository = LocalFavoritesRepository();
      await profileRepository.load();
      await favoritesRepository.load();

      await tester.binding.setSurfaceSize(const Size(800, 3200));
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

    testWidgets('Marrakech + puce Restaurant affiche les 11 restaurants', (
      tester,
    ) async {
      await pumpExplorer(tester);

      await tester.tap(find.text('Marrakech'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restaurant').first);
      await tester.pumpAndSettle();

      expect(find.byType(ExplorerEmptyState), findsNothing);
      expect(find.byType(PlaceGuideCard), findsNWidgets(11));
      for (final name in _restaurantNames) {
        expect(find.text(name), findsWidgets, reason: name);
      }
    });

    testWidgets(
      'Marrakech + puce Hammam sticky + recherche « restaurant » affiche les 11',
      (tester) async {
        await pumpExplorer(tester);

        await tester.tap(find.text('Marrakech'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hammam').first);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'restaurant');
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pumpAndSettle();

        expect(find.byType(ExplorerEmptyState), findsNothing);
        for (final name in _restaurantNames) {
          expect(find.text(name), findsWidgets, reason: name);
        }
      },
    );
  });
}
