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

/// Five Marrakech `monument` records (YSL stays `musee`).
const _monumentIds = <String>{
  'place-bahia',
  'place-koutoubia',
  'place-medersa-ben-youssef',
  'place-tombeaux-saadiens',
  'place-el-badi',
};

const _packageIds = <String>{
  ..._monumentIds,
  'place-ysl-museum',
};

const _monumentNames = <String>[
  'Palais de la Bahia',
  'Mosquée de la Koutoubia',
  'Médersa Ben Youssef',
  'Tombeaux Saadiens',
  'Palais El Badi',
];

/// Simule un remote seed sans les 4 monuments nouvellement ajoutés.
List<PlaceGuide> _oldRemoteWithoutNewMonuments() {
  const newIds = {
    'place-koutoubia',
    'place-medersa-ben-youssef',
    'place-tombeaux-saadiens',
    'place-el-badi',
  };
  return PlaceCatalog.guides
      .where((place) => !newIds.contains(place.id))
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

  group('Explorer runtime path — Marrakech monuments', () {
    test('PlaceMapper: puce Monument = 5 records (YSL reste Musée)', () {
      final places = PlaceMapper.filter(
        const PlaceSearchQuery(
          category: PlaceCategory.monument,
          cityName: 'Marrakech',
          strictCity: true,
        ),
      );
      expect(places.map((p) => p.id).toSet(), _monumentIds);
      expect(places, hasLength(5));
    });

    test('PlaceMapper: texte « monument » renvoie les 5 monuments', () {
      final places = PlaceMapper.filter(
        const PlaceSearchQuery(
          text: 'monument',
          cityName: 'Marrakech',
          strictCity: true,
        ),
      );
      expect(places.map((p) => p.id).toSet(), _monumentIds);
    });

    test('PlaceMapper: Marrakech Toutes contient le package de 6', () {
      final places = PlaceMapper.filter(
        const PlaceSearchQuery(
          cityName: 'Marrakech',
          strictCity: true,
        ),
      );
      expect(places.map((p) => p.id).toSet(), containsAll(_packageIds));
    });

    test(
      'ResilientPlaceRepository: monuments locaux après warmUp distant vieux',
      () async {
        late ResilientPlaceRepository repository;
        PlaceRepository.registerFactory(() {
          repository = ResilientPlaceRepository(
            local: LocalPlaceRepository(),
            fetchRemote: () async => _oldRemoteWithoutNewMonuments(),
          );
          return repository;
        });

        final repo = PlaceRepository.instance;
        await repo.warmUp();

        final byCategory = repo.search(
          const PlaceSearchQuery(
            text: '',
            category: PlaceCategory.monument,
            cityName: 'Marrakech',
            sort: PlaceSort.catalog,
            strictCity: true,
          ),
        );
        expect(byCategory.map((p) => p.id).toSet(), _monumentIds);

        final ysl = repo.search(
          const PlaceSearchQuery(
            text: 'yves saint laurent',
            cityName: 'Marrakech',
            sort: PlaceSort.catalog,
            strictCity: true,
          ),
        );
        expect(ysl.map((p) => p.id), contains('place-ysl-museum'));
      },
    );
  });

  group('ExplorerPage widget — Marrakech monuments', () {
    Future<void> pumpExplorer(WidgetTester tester) async {
      PlaceRepository.registerFactory(() {
        return ResilientPlaceRepository(
          local: LocalPlaceRepository(),
          fetchRemote: () async => _oldRemoteWithoutNewMonuments(),
        );
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

    testWidgets('Marrakech + puce Monument affiche les 5 monuments', (
      tester,
    ) async {
      await pumpExplorer(tester);

      await tester.tap(find.text('Marrakech'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Monument').first);
      await tester.pumpAndSettle();

      expect(find.byType(ExplorerEmptyState), findsNothing);
      for (final name in _monumentNames) {
        expect(find.text(name), findsWidgets, reason: name);
      }
      expect(find.byType(PlaceGuideCard), findsNWidgets(5));
      expect(find.text('Musée Yves Saint Laurent Marrakech'), findsNothing);
      expect(find.text('Jardin Majorelle'), findsNothing);
    });

    testWidgets('Marrakech + recherche « médersa » trouve Ben Youssef', (
      tester,
    ) async {
      await pumpExplorer(tester);

      await tester.tap(find.text('Marrakech'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'médersa');
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(find.byType(ExplorerEmptyState), findsNothing);
      expect(find.text('Médersa Ben Youssef'), findsWidgets);
    });
  });
}
