import 'package:atlas/core/editorial/editorial_catalog_load_state.dart';
import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/domain/models/place_models.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/explorer/presentation/pages/explorer_page.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_catalog_status_indicator.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/domain/favorite_entity_type.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';
import 'package:atlas/features/map/data/map_place_query.dart';
import 'package:atlas/features/map/domain/atlas_map_models.dart';
import 'package:atlas/features/map/presentation/pages/atlas_map_page.dart';
import 'package:atlas/features/map/presentation/widgets/atlas_flutter_map_view.dart';
import 'package:atlas/features/map/presentation/widgets/place_map_preview_sheet.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';
import 'package:atlas/features/shell/presentation/shell_navigation_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaceBrowseFilters.resetForTest();
    EditorialRepositoryBootstrap.registerDefaults();
    AtlasFlutterMapView.useSilentTiles = true;
  });

  tearDown(PlaceBrowseFilters.resetForTest);

  /// flutter_map keeps scheduling frames — never use pumpAndSettle with it.
  Future<void> pumpFrames(WidgetTester tester, [int n = 3]) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpMap(
    WidgetTester tester, {
    required Size size,
    LocalFavoritesRepository? favorites,
  }) async {
    final profile = LocalProfileRepository();
    final fav = favorites ?? LocalFavoritesRepository();
    await profile.load();
    await fav.load();
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProfileScope(
        repository: profile,
        child: FavoritesScope(
          repository: fav,
          child: MaterialApp(
            theme: AtlasTheme.light,
            home: const Scaffold(body: AtlasMapPage(isActive: true)),
          ),
        ),
      ),
    );
    await pumpFrames(tester);
  }

  group('visual checklist — mobile', () {
    testWidgets('attribution OSM visible + clustering layer present', (
      tester,
    ) async {
      await pumpMap(tester, size: const Size(390, 844));

      expect(find.text('Carte'), findsOneWidget);
      expect(find.textContaining('OpenStreetMap'), findsWidgets);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(MarkerClusterLayerWidget), findsOneWidget);
      expect(find.byType(RichAttributionWidget), findsOneWidget);

      // Clustering config: individual markers above zoom 14.
      expect(AtlasFlutterMapView.clusterMaxZoom, 14);
    });

    testWidgets('sync city / category / search / favorites with filters', (
      tester,
    ) async {
      final favorites = LocalFavoritesRepository();
      await favorites.load();
      await favorites.addFavorite(
        entityType: FavoriteEntityType.place,
        entitySlug: 'place-majorelle',
      );

      PlaceBrowseFilters.instance
        ..setCityName('Casablanca', notify: false)
        ..setCategory(PlaceCategory.monument, notify: false)
        ..setSearchText('Hassan', notify: false)
        ..setFavoritesOnly(false, notify: false);

      await pumpMap(tester, size: const Size(390, 844), favorites: favorites);

      expect(find.text('Casablanca'), findsWidgets);
      expect(PlaceBrowseFilters.instance.cityName, 'Casablanca');
      expect(PlaceBrowseFilters.instance.category, PlaceCategory.monument);
      expect(PlaceBrowseFilters.instance.searchText, 'Hassan');

      // Favorites-only mode.
      await tester.tap(find.text('Favoris'));
      await tester.pump();
      expect(PlaceBrowseFilters.instance.favoritesOnly, isTrue);

      final markers = MapPlaceQuery.markers(
        repository: LocalPlaceRepository(),
        filters: PlaceBrowseFilters.instance
          ..setCityName('Marrakech', notify: false)
          ..setCategory(null, notify: false)
          ..setSearchText('', notify: false),
        favorites: favorites,
      );
      expect(markers, hasLength(1));
      expect(markers.single.placeId, 'place-majorelle');
    });

    testWidgets('preview sheet ouvre le détail existant', (tester) async {
      // Isolated from FlutterMap — continuous map frames hang pump/settle.
      final place = LocalPlaceRepository().findById('place-majorelle')!;
      final profile = LocalProfileRepository();
      final favorites = LocalFavoritesRepository();
      await profile.load();
      await favorites.load();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProfileScope(
          repository: profile,
          child: FavoritesScope(
            repository: favorites,
            child: MaterialApp(
              theme: AtlasTheme.light,
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: Center(
                      child: TextButton(
                        onPressed: () => showPlaceMapPreviewSheet(
                          context,
                          place: place,
                        ),
                        child: const Text('open-preview'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('open-preview'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PlaceMapPreviewSheet), findsOneWidget);
      expect(find.text('Jardin Majorelle'), findsWidgets);
      expect(find.text('Voir la fiche complète'), findsOneWidget);

      await tester.tap(find.text('Voir la fiche complète'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Conseils pratiques'), findsOneWidget);
    });

    testWidgets('stale/offline indicator visible when catalog stale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: const Scaffold(
            body: PlaceCatalogStatusIndicator(
              loadState: EditorialCatalogLoadState.stale,
            ),
          ),
        ),
      );
      expect(find.text('Catalogue local'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: const Scaffold(
            body: PlaceCatalogStatusIndicator(
              loadState: EditorialCatalogLoadState.error,
            ),
          ),
        ),
      );
      expect(find.text('Hors ligne'), findsOneWidget);
    });
  });

  group('visual checklist — web', () {
    testWidgets('layout large + attribution + pas de pin sans coords', (
      tester,
    ) async {
      await pumpMap(tester, size: const Size(1280, 900));

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.textContaining('OpenStreetMap'), findsWidgets);
      expect(find.byType(RichAttributionWidget), findsOneWidget);
      expect(find.byType(MarkerClusterLayerWidget), findsOneWidget);

      final markers = MapPlaceQuery.markers(
        repository: LocalPlaceRepository(),
        filters: PlaceBrowseFilters.instance
          ..setCityName('Marrakech', notify: false),
      );
      expect(markers.any((m) => m.placeId == 'place-hammam-marrakech'), isFalse);
      expect(
        markers.every((m) => m.latitude.isFinite && m.longitude.isFinite),
        isTrue,
      );
    });
  });

  testWidgets('Explorer et Carte partagent les filtres', (tester) async {
    final profile = LocalProfileRepository();
    final favorites = LocalFavoritesRepository();
    await profile.load();
    await favorites.load();

    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var openedMap = false;
    await tester.pumpWidget(
      ProfileScope(
        repository: profile,
        child: FavoritesScope(
          repository: favorites,
          child: MaterialApp(
            theme: AtlasTheme.light,
            home: ShellNavigationScope(
              navigateToTab: (index) {
                if (index == AtlasShellTab.map) openedMap = true;
              },
              child: const Scaffold(body: ExplorerPage()),
            ),
          ),
        ),
      ),
    );
    await pumpFrames(tester, 6);

    // City chip Casablanca
    await tester.tap(find.text('Casablanca'));
    await pumpFrames(tester, 4);
    expect(PlaceBrowseFilters.instance.cityName, 'Casablanca');

    // Category Jardin
    await tester.tap(find.text('Jardin'));
    await pumpFrames(tester, 4);
    expect(PlaceBrowseFilters.instance.category, PlaceCategory.jardin);

    // Search
    await tester.enterText(find.byType(TextField).first, 'Majorelle');
    await tester.pump(const Duration(milliseconds: 250));
    expect(PlaceBrowseFilters.instance.searchText, 'Majorelle');

    // Open map from Explorer
    await tester.tap(find.byTooltip('Ouvrir la carte'));
    await tester.pump();
    expect(openedMap, isTrue);
  });

  test('tile provider exposes OSM attribution', () {
    const provider = OsmAtlasMapTileProvider();
    expect(provider.attribution, contains('OpenStreetMap'));
    expect(provider.layers, isNotEmpty);
  });

  test('stale/offline : catalogue local sert les marqueurs', () {
    final filters = PlaceBrowseFilters.instance
      ..setCityName('Rabat', notify: false);
    final markers = MapPlaceQuery.markers(
      repository: LocalPlaceRepository(),
      filters: filters,
    );
    expect(markers, isNotEmpty);
    expect(markers.every((m) => m.placeId.startsWith('place-')), isTrue);
  });

  test('individual markers at higher zoom (clusterMaxZoom = 14)', () {
    expect(AtlasFlutterMapView.clusterMaxZoom, 14);
  });
}
