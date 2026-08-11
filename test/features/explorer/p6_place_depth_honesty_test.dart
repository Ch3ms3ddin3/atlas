import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/data/place_catalog.dart';
import 'package:atlas/features/explorer/data/place_cover_assets.dart';
import 'package:atlas/features/explorer/data/place_mapper.dart';
import 'package:atlas/features/explorer/domain/models/place_models.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/explorer/domain/place_repository.dart';
import 'package:atlas/features/explorer/presentation/pages/place_detail_page.dart';
import 'package:atlas/features/explorer/presentation/widgets/explorer_hero.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_category_filter.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_cover_image.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_display_helpers.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_guide_card.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/domain/favorite_entity_type.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaceBrowseFilters.resetForTest();
    PlaceRepository.resetForTest();
    PlaceRepository.registerFactory(LocalPlaceRepository.new);
    EditorialRepositoryBootstrap.registerDefaults();
  });

  tearDown(() {
    PlaceBrowseFilters.resetForTest();
    PlaceRepository.resetForTest();
  });

  group('P6 cover honesty', () {
    test('bundled covers include jemaa and ysl; exclude majorelle and hammams', () {
      expect(PlaceCoverAssets.hasBundledCover('place-bahia'), isTrue);
      expect(PlaceCoverAssets.hasBundledCover('place-jemaa-el-fna'), isTrue);
      expect(PlaceCoverAssets.hasBundledCover('place-ysl-museum'), isTrue);
      expect(PlaceCoverAssets.hasBundledCover('place-hassan-ii'), isTrue);
      expect(PlaceCoverAssets.hasBundledCover('place-majorelle'), isFalse);
      expect(
        PlaceCoverAssets.hasBundledCover('place-hammam-marrakech'),
        isFalse,
      );
      expect(
        PlaceCoverAssets.hasBundledCover('place-les-bains-marrakech'),
        isFalse,
      );
      expect(PlaceCoverAssets.bundledPlaceIds.length, 13);
    });

    testWidgets('PlaceCoverImage uses Image.asset for bundled cover', (
      tester,
    ) async {
      final bahia = PlaceCatalog.guides.firstWhere(
        (p) => p.id == 'place-bahia',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: Scaffold(body: PlaceCoverImage(place: bahia, height: 140)),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(PlaceImageFallback), findsNothing);
    });

    testWidgets('PlaceCoverImage fallback when no verified image', (
      tester,
    ) async {
      final majorelle = PlaceCatalog.guides.firstWhere(
        (p) => p.id == 'place-majorelle',
      );
      expect(majorelle.primaryImageUrl, isNull);
      expect(PlaceCoverAssets.hasBundledCover(majorelle.id), isFalse);

      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: Scaffold(body: PlaceCoverImage(place: majorelle, height: 140)),
        ),
      );

      expect(find.byType(PlaceImageFallback), findsOneWidget);
      expect(find.byIcon(Icons.park_outlined), findsOneWidget);
    });
  });

  group('P6 soft-misleading removal', () {
    test('inventory categories include café after Marrakech café V1', () {
      final cats = PlaceMapper.categoriesPresentIn(PlaceCatalog.guides);
      expect(cats, contains(PlaceCategory.cafe));
      expect(cats, contains(PlaceCategory.jardin));
      expect(cats, contains(PlaceCategory.monument));
      expect(
        LocalPlaceRepository().categories,
        contains(PlaceCategory.cafe),
      );
    });

    testWidgets('category filter shows Café chip when cafés exist', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: Scaffold(
            body: PlaceCategoryFilter(
              selectedCategory: null,
              availableCategories: PlaceMapper.categoriesPresentIn(
                PlaceCatalog.guides,
              ),
              onCategorySelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Café'), findsOneWidget);
      expect(find.text('Jardin'), findsOneWidget);
      expect(find.text('Monument'), findsOneWidget);
    });

    testWidgets('guide card omits duration chip when not tip-derived', (
      tester,
    ) async {
      final favorites = LocalFavoritesRepository();
      await favorites.load();
      final majorelle = PlaceCatalog.guides.firstWhere(
        (p) => p.id == 'place-majorelle',
      );
      expect(PlaceDisplayHelpers.visitDuration(majorelle), isNull);

      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: FavoritesScope(
            repository: favorites,
            child: Scaffold(
              body: PlaceGuideCard(place: majorelle, onTap: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.schedule_outlined), findsNothing);
      expect(find.text('1h30'), findsNothing);
    });

    testWidgets('Explorer hero copy matches covered cities only', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ExplorerHero())),
      );
      expect(find.textContaining('meilleurs lieux du Maroc'), findsNothing);
      expect(
        find.textContaining('Marrakech, Casablanca et Rabat'),
        findsOneWidget,
      );
    });
  });

  group('P6 place detail / favorites', () {
    testWidgets('detail hides optional empty sections', (tester) async {
      final favorites = LocalFavoritesRepository();
      await favorites.load();
      final majorelle = PlaceCatalog.guides.firstWhere(
        (p) => p.id == 'place-majorelle',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: FavoritesScope(
            repository: favorites,
            child: PlaceDetailPage(place: majorelle),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Horaires'), findsNothing);
      expect(find.text('Galerie'), findsNothing);
      expect(find.text('Accessibilité'), findsNothing);
      expect(find.text('Équipements'), findsNothing);
      expect(find.text('Jardin Majorelle'), findsWidgets);
      expect(find.text('Carte Atlas'), findsOneWidget);
    });

    testWidgets('favorites toggle remains on guide card', (tester) async {
      final favorites = LocalFavoritesRepository();
      await favorites.load();
      final place = PlaceCatalog.guides.firstWhere(
        (p) => p.id == 'place-bahia',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: FavoritesScope(
            repository: favorites,
            child: Scaffold(
              body: PlaceGuideCard(place: place, onTap: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Ajouter aux favoris'));
      await tester.pump();
      expect(
        favorites.isFavorite(
          entityType: FavoriteEntityType.place,
          entitySlug: 'place-bahia',
        ),
        isTrue,
      );
    });

    test('catalog size and categories remain honest after Marrakech monuments V1', () {
      expect(PlaceCatalog.guides, hasLength(32));
      expect(
        PlaceCatalog.guides.any((p) => p.name == 'Hammam traditionnel'),
        isFalse,
      );
      expect(
        PlaceCatalog.guides.any((p) => p.id == 'place-bain-de-kasbah'),
        isFalse,
      );
      expect(
        PlaceMapper.categoriesPresentIn(PlaceCatalog.guides),
        contains(PlaceCategory.cafe),
      );
      expect(
        PlaceMapper.categoriesPresentIn(PlaceCatalog.guides),
        contains(PlaceCategory.hammam),
      );
      expect(
        PlaceMapper.categoriesPresentIn(PlaceCatalog.guides),
        contains(PlaceCategory.restaurant),
      );
      expect(
        PlaceMapper.categoriesPresentIn(PlaceCatalog.guides),
        contains(PlaceCategory.monument),
      );
      expect(
        PlaceCatalog.guides.where(
          (p) =>
              p.cityName == 'Marrakech' &&
              p.category == PlaceCategory.restaurant,
        ),
        hasLength(5),
      );
      expect(
        PlaceCatalog.guides.where(
          (p) =>
              p.cityName == 'Marrakech' && p.category == PlaceCategory.cafe,
        ),
        hasLength(5),
      );
      expect(
        PlaceCatalog.guides.where(
          (p) =>
              p.cityName == 'Marrakech' &&
              p.category == PlaceCategory.monument,
        ),
        hasLength(5),
      );
      expect(
        PlaceCatalog.guides.where(
          (p) => p.id == 'place-dar-el-bacha' || p.name.contains('Dar El Bacha Musée'),
        ),
        isEmpty,
      );
    });
  });

  group('P6 map focus request', () {
    test('requestFocusPlace sets city and clears other filters', () {
      final filters = PlaceBrowseFilters.instance;
      filters.setCategory(PlaceCategory.monument);
      filters.setSearchText('x');
      filters.setFavoritesOnly(true);

      filters.requestFocusPlace(placeId: 'place-bahia', cityName: 'Marrakech');

      expect(filters.focusPlaceId, 'place-bahia');
      expect(filters.cityName, 'Marrakech');
      expect(filters.category, isNull);
      expect(filters.searchText, isEmpty);
      expect(filters.favoritesOnly, isFalse);
      expect(filters.consumeFocusPlaceId(), 'place-bahia');
      expect(filters.focusPlaceId, isNull);
    });
  });
}
