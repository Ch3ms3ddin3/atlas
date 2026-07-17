import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';
import 'package:atlas/features/map/presentation/pages/atlas_map_page.dart';
import 'package:atlas/features/map/presentation/widgets/atlas_flutter_map_view.dart';
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
  });

  testWidgets('carte affiche le titre et les filtres', (tester) async {
    final profile = LocalProfileRepository();
    final favorites = LocalFavoritesRepository();
    await profile.load();
    await favorites.load();

    await tester.binding.setSurfaceSize(const Size(800, 1400));
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

    expect(find.text('Carte'), findsOneWidget);
    expect(find.text('Favoris'), findsOneWidget);
    expect(find.text('Marrakech'), findsWidgets);
  });
}
