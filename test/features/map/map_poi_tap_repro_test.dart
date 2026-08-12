import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/content_reports/data/local_content_reports_repository.dart';
import 'package:atlas/features/content_reports/presentation/content_reports_scope.dart';
import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/explorer/presentation/pages/place_detail_page.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/domain/favorite_entity_type.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';
import 'package:atlas/features/favorites/presentation/widgets/favorite_toggle_button.dart';
import 'package:atlas/features/map/presentation/widgets/atlas_flutter_map_view.dart';
import 'package:atlas/features/map/presentation/widgets/place_map_preview_sheet.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression: map POI → preview → detail must inherit app scopes that live
/// above the navigator (FavoritesScope + ContentReportsScope), matching AtlasApp.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaceBrowseFilters.resetForTest();
    EditorialRepositoryBootstrap.registerDefaults();
    AtlasFlutterMapView.useSilentTiles = true;
  });

  tearDown(PlaceBrowseFilters.resetForTest);

  Future<
    ({
      LocalFavoritesRepository favorites,
      LocalContentReportsRepository reports,
    })
  >
  pumpMapPoiHarness(WidgetTester tester) async {
    final profile = LocalProfileRepository();
    final favorites = LocalFavoritesRepository();
    final reports = LocalContentReportsRepository();
    await profile.load();
    await favorites.load();
    await reports.load();

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        // Production-like: scopes above the navigator (AtlasApp.builder).
        builder: (context, child) {
          return FavoritesScope(
            repository: favorites,
            child: ContentReportsScope(
              repository: reports,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: ProfileScope(
          repository: profile,
          child: Builder(
            builder: (pageContext) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final id in ['place-majorelle', 'place-bahia'])
                        TextButton(
                          onPressed: () {
                            final place = LocalPlaceRepository().findById(id)!;
                            showPlaceMapPreviewSheet(pageContext, place: place);
                          },
                          child: Text('open-$id'),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    return (favorites: favorites, reports: reports);
  }

  Future<void> openPreviewAndDetail(
    WidgetTester tester, {
    required String placeId,
    required String placeName,
  }) async {
    await tester.tap(find.text('open-$placeId'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.byType(PlaceMapPreviewSheet), findsOneWidget);
    expect(find.text(placeName), findsWidgets);
    expect(find.text('Voir la fiche'), findsOneWidget);

    await tester.tap(find.text('Voir la fiche'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.byType(PlaceDetailPage), findsOneWidget);
    expect(find.text(placeName), findsWidgets);
    expect(find.byType(FavoriteToggleButton), findsWidgets);
  }

  testWidgets('tap Jardin Majorelle on map opens preview + detail', (
    tester,
  ) async {
    await pumpMapPoiHarness(tester);
    await openPreviewAndDetail(
      tester,
      placeId: 'place-majorelle',
      placeName: 'Jardin Majorelle',
    );
  });

  testWidgets('tap Palais Bahia on map opens preview + detail', (tester) async {
    await pumpMapPoiHarness(tester);
    await openPreviewAndDetail(
      tester,
      placeId: 'place-bahia',
      placeName: 'Palais Bahia',
    );
  });

  testWidgets('map POI detail can toggle favorite and open report sheet', (
    tester,
  ) async {
    final repos = await pumpMapPoiHarness(tester);

    await openPreviewAndDetail(
      tester,
      placeId: 'place-bahia',
      placeName: 'Palais Bahia',
    );

    await tester.tap(find.byTooltip('Ajouter aux favoris').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      repos.favorites.isFavorite(
        entityType: FavoriteEntityType.place,
        entitySlug: 'place-bahia',
      ),
      isTrue,
    );

    await tester.tap(find.byTooltip('Signaler un problème'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('Signaler un problème'), findsWidgets);
    expect(find.text('Envoyer'), findsOneWidget);
  });
}
