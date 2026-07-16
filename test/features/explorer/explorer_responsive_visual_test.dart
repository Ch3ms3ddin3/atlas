import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/explorer/domain/place_repository.dart';
import 'package:atlas/features/explorer/presentation/pages/explorer_page.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_guide_card.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';
import 'package:atlas/features/shell/presentation/shell_navigation_scope.dart';

/// Vérifie le rendu Explorer aux largeurs mobile et web (≥720 contenu).
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    ensurePrayerNotificationCoordinatorForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaceRepository.resetForTest();
    EditorialRepositoryBootstrap.registerDefaults();
  });

  tearDown(() {
    PlaceRepository.resetForTest();
  });

  Future<void> pumpAt(
    WidgetTester tester, {
    required Size size,
  }) async {
    final profile = LocalProfileRepository();
    final favorites = LocalFavoritesRepository();
    await profile.load();
    await favorites.load();

    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: ProfileScope(
            repository: profile,
            child: FavoritesScope(
              repository: favorites,
              child: ShellNavigationScope(
                navigateToTab: (_) {},
                child: const Scaffold(body: ExplorerPage()),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mobile: liste verticale avec cartes premium', (tester) async {
    await pumpAt(tester, size: const Size(390, 844));

    expect(find.text('Explorer'), findsOneWidget);
    expect(find.text('Jardin Majorelle'), findsOneWidget);
    expect(find.text('Sélection'), findsWidgets);
    expect(find.byType(PlaceGuideCard), findsWidgets);
    expect(find.byTooltip('Ajouter aux favoris'), findsWidgets);
    expect(find.byType(SliverGrid), findsNothing);
  });

  testWidgets('web large: grille 2 colonnes', (tester) async {
    // Padding Atlas wide (48×2) → largeur utile ≥720 nécessite ~820+.
    await pumpAt(tester, size: const Size(960, 900));

    expect(find.text('Explorer'), findsOneWidget);
    expect(find.text('Jardin Majorelle'), findsOneWidget);
    expect(find.byType(PlaceGuideCard), findsWidgets);
    expect(find.byType(SliverGrid), findsOneWidget);
  });
}
