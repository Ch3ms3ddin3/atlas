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
import 'package:atlas/features/explorer/presentation/pages/place_detail_page.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_catalog_status_indicator.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/domain/favorite_entity_type.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';
import 'package:atlas/features/shell/presentation/shell_navigation_scope.dart';
import 'package:atlas/features/shell/presentation/shell_tab_scroll_registry.dart';

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
              scrollRegistry: ShellTabScrollRegistry(),
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
    expect(
      find.textContaining('Sélection Atlas pour Marrakech'),
      findsOneWidget,
    );
    expect(find.text('Sélection Atlas'), findsWidgets);
    expect(find.text('✨ Sélection Atlas'), findsNothing);
    // Featured card is Jemaa (first beta core), Majorelle still in list.
    expect(find.text('Place Jemaa el-Fna'), findsWidgets);
    expect(find.text('Jardin Majorelle'), findsWidgets);
    expect(find.text('Marrakech'), findsWidgets);
    expect(find.text('Casablanca'), findsOneWidget);
    expect(find.text('Rabat'), findsOneWidget);
    expect(find.text('Tanger'), findsNothing);
    expect(find.text('Fès'), findsNothing);
    expect(find.text('Agadir'), findsNothing);
    expect(
      find.text('Contenu bientôt disponible pour cette ville.'),
      findsNothing,
    );
  });

  testWidgets('filtre catégorie réduit la liste', (tester) async {
    await pumpExplorer(tester);

    await tester.tap(find.text('Jardin'));
    await tester.pumpAndSettle();

    expect(find.text('Jardin Majorelle'), findsOneWidget);
    expect(find.text('Palais Bahia'), findsNothing);
  });

  testWidgets('recherche par texte après debounce', (tester) async {
    await pumpExplorer(tester);

    await tester.enterText(find.byType(TextField), 'majorelle');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.text('Jardin Majorelle'), findsWidgets);
    expect(find.text('Palais Bahia'), findsNothing);
  });

  testWidgets('recherche sans résultat affiche empty state V2', (tester) async {
    await pumpExplorer(tester);

    await tester.enterText(find.byType(TextField), 'zzzzzzzz');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.text('Aucun lieu trouvé'), findsOneWidget);
    expect(find.text('Essayez une autre catégorie.'), findsOneWidget);
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
        entitySlug: 'place-jemaa-el-fna',
      ),
      isTrue,
    );
  });

  testWidgets('carte ouvre le détail au tap', (tester) async {
    await pumpExplorer(tester);

    await tester.tap(find.text('Jardin Majorelle').first);
    await tester.pumpAndSettle();

    expect(find.byType(PlaceDetailPage), findsOneWidget);
    expect(find.text('Conseils pratiques'), findsOneWidget);
    expect(find.byTooltip('Retour'), findsOneWidget);
    expect(find.text('Guéliz · Marrakech'), findsOneWidget);
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

  testWidgets('profil sur ville non couverte replie vers Marrakech', (
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

    expect(find.text('Tanger'), findsNothing);
    expect(find.text('Jardin Majorelle'), findsWidgets);
    expect(find.textContaining('Contenu bientôt disponible'), findsNothing);
  });
}
