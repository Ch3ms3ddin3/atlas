import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/editorial/editorial_catalog_load_state.dart';
import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/data/resilient_place_repository.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/explorer/domain/place_repository.dart';
import 'package:atlas/features/explorer/presentation/pages/explorer_page.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_catalog_status_indicator.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_guide_card.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/domain/favorite_entity_type.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';
import 'package:atlas/features/shell/presentation/shell_navigation_scope.dart';

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
  });

  tearDown(() {
    PlaceRepository.resetForTest();
    PlaceBrowseFilters.resetForTest();
  });

  Future<void> pumpExplorer(
    WidgetTester tester, {
    LocalProfileRepository? profile,
    LocalFavoritesRepository? favorites,
  }) async {
    final profileRepository = profile ?? LocalProfileRepository();
    final favoritesRepository = favorites ?? LocalFavoritesRepository();
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

  testWidgets('affiche les lieux de Marrakech par défaut', (tester) async {
    await pumpExplorer(tester);

    expect(find.text('Explorer'), findsOneWidget);
    expect(find.text('Jardin Majorelle'), findsOneWidget);
    expect(find.text('Tanger'), findsOneWidget);
    expect(find.text('Contenu bientôt disponible pour cette ville.'), findsNothing);
  });

  testWidgets('ville sans contenu affiche empty state premium', (tester) async {
    await pumpExplorer(tester);

    await tester.tap(find.text('Tanger'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Contenu bientôt disponible pour cette ville'),
      findsWidgets,
    );
    expect(find.text('Jardin Majorelle'), findsNothing);
    expect(find.byType(PlaceGuideCard), findsNothing);
  });

  testWidgets('filtre catégorie réduit la liste', (tester) async {
    await pumpExplorer(tester);

    await tester.tap(find.text('Jardin'));
    await tester.pumpAndSettle();

    expect(find.text('Jardin Majorelle'), findsOneWidget);
    expect(find.text('Palais de la Bahia'), findsNothing);
  });

  testWidgets('recherche par texte après debounce', (tester) async {
    await pumpExplorer(tester);

    await tester.enterText(find.byType(TextField), 'majorelle');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.text('Jardin Majorelle'), findsOneWidget);
    expect(find.text('Palais de la Bahia'), findsNothing);
  });

  testWidgets('favori sur carte sans ouvrir le détail', (tester) async {
    final favorites = LocalFavoritesRepository();
    await pumpExplorer(tester, favorites: favorites);

    expect(find.byTooltip('Ajouter aux favoris'), findsWidgets);

    await tester.tap(find.byTooltip('Ajouter aux favoris').first);
    await tester.pumpAndSettle();

    expect(find.text('Conseils pratiques'), findsNothing);
    expect(
      favorites.isFavorite(
        entityType: FavoriteEntityType.place,
        entitySlug: 'place-majorelle',
      ),
      isTrue,
    );
  });

  testWidgets('carte ouvre le détail au tap', (tester) async {
    await pumpExplorer(tester);

    await tester.tap(find.text('Jardin Majorelle'));
    await tester.pumpAndSettle();

    expect(find.text('Conseils pratiques'), findsOneWidget);
  });

  testWidgets('indicateur catalogue visible seulement en stale/error', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlaceCatalogStatusIndicator(
            loadState: EditorialCatalogLoadState.success,
          ),
        ),
      ),
    );
    expect(find.text('Hors ligne'), findsNothing);
    expect(find.text('Catalogue local'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlaceCatalogStatusIndicator(
            loadState: EditorialCatalogLoadState.stale,
          ),
        ),
      ),
    );
    expect(find.text('Catalogue local'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlaceCatalogStatusIndicator(
            loadState: EditorialCatalogLoadState.error,
          ),
        ),
      ),
    );
    expect(find.text('Hors ligne'), findsOneWidget);
  });

  testWidgets('catalogue distant vide (stale) garde la liste locale', (
    tester,
  ) async {
    PlaceRepository.registerFactory(
      () => ResilientPlaceRepository(
        local: LocalPlaceRepository(),
        fetchRemote: () async => const [],
      ),
    );
    await PlaceRepository().warmUp();

    await pumpExplorer(tester);

    expect(find.text('Jardin Majorelle'), findsOneWidget);
    expect(find.text('Catalogue local'), findsOneWidget);
  });

  testWidgets('profil sur ville non couverte démarre sur empty state', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'profile_first_name': 'Voyageur',
      'profile_preferred_city': 'Tanger',
    });
    final profile = LocalProfileRepository();
    await profile.load();
    expect(profile.profile.preferredCity, 'Tanger');

    await pumpExplorer(tester, profile: profile);

    expect(find.text('Jardin Majorelle'), findsNothing);
    expect(
      find.textContaining('Contenu bientôt disponible'),
      findsWidgets,
    );
  });
}
