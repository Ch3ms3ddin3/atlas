import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/core/platform/atlas_external_links.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_cover_image.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/domain/favorite_entity_type.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';
import 'package:atlas/features/favorites/presentation/widgets/favorite_toggle_button.dart';
import 'package:atlas/features/map/presentation/pages/atlas_map_page.dart';
import 'package:atlas/features/map/presentation/widgets/atlas_flutter_map_view.dart';
import 'package:atlas/features/map/presentation/widgets/place_map_preview_sheet.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaceBrowseFilters.resetForTest();
    EditorialRepositoryBootstrap.registerDefaults();
    AtlasFlutterMapView.useSilentTiles = true;
    AtlasExternalLinks.resetForTest();
  });

  tearDown(() {
    PlaceBrowseFilters.resetForTest();
    AtlasExternalLinks.resetForTest();
  });

  testWidgets('near-me button always visible without prior location grant', (
    tester,
  ) async {
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
            home: const Scaffold(body: AtlasMapPage(isActive: true)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byTooltip('Près de moi'), findsOneWidget);
  });

  testWidgets('preview sheet shows cover, meta, favorite and itinerary', (
    tester,
  ) async {
    final place = LocalPlaceRepository().findById('place-majorelle')!;
    final profile = LocalProfileRepository();
    final favorites = LocalFavoritesRepository();
    await profile.load();
    await favorites.load();

    Uri? openedUri;
    AtlasExternalLinks.openForTest((uri) async {
      openedUri = uri;
      return true;
    });

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
    expect(find.byType(PlaceCoverImage), findsOneWidget);
    expect(find.text('Jardin Majorelle'), findsWidgets);
    expect(find.textContaining('Jardin'), findsWidgets);
    expect(find.textContaining(place.priceLevel), findsWidgets);
    expect(find.byType(FavoriteToggleButton), findsOneWidget);
    expect(find.text('Itinéraire'), findsOneWidget);
    expect(find.text('Voir la fiche'), findsOneWidget);

    await tester.tap(find.byTooltip('Ajouter aux favoris'));
    await tester.pumpAndSettle();
    expect(
      favorites.isFavorite(
        entityType: FavoriteEntityType.place,
        entitySlug: 'place-majorelle',
      ),
      isTrue,
    );

    await tester.tap(find.text('Itinéraire'));
    await tester.pumpAndSettle();
    expect(openedUri, isNotNull);
    expect(openedUri.toString(), contains('${place.latitude}'));
    expect(openedUri.toString(), contains('${place.longitude}'));
  });
}
