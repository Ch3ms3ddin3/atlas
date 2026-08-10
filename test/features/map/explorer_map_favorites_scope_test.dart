import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/content_reports/data/local_content_reports_repository.dart';
import 'package:atlas/features/content_reports/presentation/content_reports_scope.dart';
import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/explorer/domain/place_repository.dart';
import 'package:atlas/features/explorer/presentation/pages/explorer_page.dart';
import 'package:atlas/features/explorer/presentation/pages/place_detail_page.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';
import 'package:atlas/features/favorites/presentation/widgets/favorite_toggle_button.dart';
import 'package:atlas/features/map/presentation/widgets/atlas_flutter_map_view.dart';
import 'package:atlas/features/map/presentation/widgets/place_map_preview_sheet.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';
import 'package:atlas/features/shell/presentation/shell_navigation_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression: Explorer → Majorelle → map preview/detail keeps app scopes.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    ensurePrayerNotificationCoordinatorForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaceRepository.resetForTest();
    PlaceBrowseFilters.resetForTest();
    EditorialRepositoryBootstrap.registerDefaults();
    AtlasFlutterMapView.useSilentTiles = true;
  });

  tearDown(() {
    PlaceRepository.resetForTest();
    PlaceBrowseFilters.resetForTest();
  });

  testWidgets(
    'Explorer → Jardin Majorelle → open on map keeps FavoritesScope',
    (tester) async {
      final profile = LocalProfileRepository();
      final favorites = LocalFavoritesRepository();
      final reports = LocalContentReportsRepository();
      await profile.load();
      await favorites.load();
      await reports.load();

      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var tabIndex = AtlasShellTab.explorer;

      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          builder: (context, child) {
            return FavoritesScope(
              repository: favorites,
              child: ContentReportsScope(
                repository: reports,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          home: StatefulBuilder(
            builder: (context, setState) {
              return ProfileScope(
                repository: profile,
                child: ShellNavigationScope(
                  navigateToTab: (index) {
                    setState(() => tabIndex = index);
                  },
                  child: Scaffold(
                    body: IndexedStack(
                      index: tabIndex == AtlasShellTab.map ? 1 : 0,
                      children: [
                        const ExplorerPage(),
                        Builder(
                          builder: (mapContext) {
                            return Column(
                              children: [
                                const Expanded(
                                  child: Center(child: Text('Carte')),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final place = LocalPlaceRepository()
                                        .findById('place-majorelle')!;
                                    showPlaceMapPreviewSheet(
                                      mapContext,
                                      place: place,
                                    );
                                  },
                                  child: const Text('open-majorelle-on-map'),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jardin Majorelle'), findsWidgets);
      await tester.tap(find.text('Jardin Majorelle').first);
      await tester.pumpAndSettle();
      expect(find.byType(PlaceDetailPage), findsOneWidget);
      expect(find.text('Conseils pratiques'), findsOneWidget);

      // Prefer Material back / close over Cupertino-only pageBack().
      final back = find.byTooltip('Back');
      final close = find.byTooltip('Close');
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back.first);
      } else if (close.evaluate().isNotEmpty) {
        await tester.tap(close.first);
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Ouvrir la carte'));
      await tester.pumpAndSettle();
      expect(find.text('open-majorelle-on-map'), findsOneWidget);

      await tester.tap(find.text('open-majorelle-on-map'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PlaceMapPreviewSheet), findsOneWidget);

      await tester.tap(find.text('Voir la fiche'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(PlaceDetailPage), findsOneWidget);
      expect(find.text('Conseils pratiques'), findsOneWidget);
      expect(find.byType(FavoriteToggleButton), findsWidgets);

      await tester.tap(find.byTooltip('Ajouter aux favoris').first);
      await tester.pumpAndSettle();
      expect(favorites.activeFavorites, isNotEmpty);
    },
  );
}
