import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/app/atlas_app.dart';
import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/design_system/theme/atlas_spacing.dart';
import 'package:atlas/features/admission_temporaire/data/at_bootstrap.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/explorer/presentation/pages/explorer_page.dart';
import 'package:atlas/features/home/presentation/pages/home_page.dart';
import 'package:atlas/features/map/presentation/pages/atlas_map_page.dart';
import 'package:atlas/features/map/presentation/widgets/atlas_flutter_map_view.dart';
import 'package:atlas/features/prices/domain/price_intelligence_repository.dart';
import 'package:atlas/features/prices/presentation/pages/prices_page.dart';
import 'package:atlas/features/procedures/presentation/pages/procedures_page.dart';
import 'package:atlas/features/profile/presentation/pages/profile_page.dart';
import 'package:atlas/features/shell/presentation/atlas_bottom_nav.dart';

import '../onboarding/onboarding_test_helpers.dart';
import '../prices/price_intelligence_test_helpers.dart';

/// iPhone 14 logical metrics — notch + home indicator.
const _iphoneSize = Size(390, 844);
const _iphoneTopInset = 47.0;
const _iphoneBottomInset = 34.0;

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    seedCompletedOnboarding();
    EditorialRepositoryBootstrap.registerDefaults();
    registerPriceIntelligenceFixtures();
    ensurePrayerNotificationCoordinatorForTests();
    ensureAtRepositoryForTests();
    AtlasFlutterMapView.useSilentTiles = true;
  });

  setUp(() {
    seedCompletedOnboarding();
    EditorialRepositoryBootstrap.registerDefaults();
    registerPriceIntelligenceFixtures();
    resetAtBootstrapForTests();
    ensureAtRepositoryForTests();
    PlaceBrowseFilters.resetForTest();
    AtlasFlutterMapView.useSilentTiles = true;
  });

  tearDown(() {
    PriceIntelligenceRepository.resetForTest();
    PlaceBrowseFilters.resetForTest();
  });

  void applyIphoneInsets(WidgetTester tester) {
    final view = tester.view;
    view.physicalSize = _iphoneSize;
    view.devicePixelRatio = 1.0;
    view.padding = const FakeViewPadding(
      top: _iphoneTopInset,
      bottom: _iphoneBottomInset,
    );
    view.viewPadding = const FakeViewPadding(
      top: _iphoneTopInset,
      bottom: _iphoneBottomInset,
    );
    addTearDown(view.reset);
  }

  Future<void> pumpAtlasApp(WidgetTester tester) async {
    applyIphoneInsets(tester);
    await tester.pumpWidget(const AtlasApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  }

  Future<void> tapBottomNav(WidgetTester tester, String label) async {
    await tester.ensureVisible(
      find.descendant(
        of: find.byType(AtlasBottomNav),
        matching: find.text(label),
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AtlasBottomNav),
        matching: find.text(label),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pumpAndSettle();
  }

  void expectTabClearsBottomNav(
    WidgetTester tester, {
    required Finder page,
    required Finder content,
    required String tabName,
  }) {
    final nav = tester.getRect(find.byType(AtlasBottomNav));
    final pageRect = tester.getRect(page);
    final contentRect = tester.getRect(content);

    expect(
      contentRect.bottom,
      lessThanOrEqualTo(nav.top + 0.5),
      reason: '$tabName: le contenu passe derrière la bottom nav',
    );
    expect(
      pageRect.bottom - contentRect.bottom,
      lessThan(8),
      reason: '$tabName: bande morte (SafeArea bottom rejoué) sous le contenu',
    );

    final padding = MediaQuery.paddingOf(tester.element(page));
    expect(
      padding.bottom,
      0,
      reason: '$tabName: padding.bottom doit être consommé par le shell',
    );
  }

  testWidgets(
    'iPhone: chaque onglet reste au-dessus de la barre sans double inset',
    (tester) async {
      await pumpAtlasApp(tester);

      expect(AtlasBottomNav.destinations, hasLength(6));
      for (final destination in AtlasBottomNav.destinations) {
        expect(
          find.descendant(
            of: find.byType(AtlasBottomNav),
            matching: find.text(destination.label),
          ),
          findsOneWidget,
        );
      }

      final nav = tester.getRect(find.byType(AtlasBottomNav));
      expect(
        nav.height,
        closeTo(AtlasSpacing.navBarHeight + _iphoneBottomInset, 0.5),
      );
      expect(
        MediaQuery.paddingOf(
          tester.element(find.byType(AtlasBottomNav)),
        ).bottom,
        _iphoneBottomInset,
      );

      expectTabClearsBottomNav(
        tester,
        page: find.byType(HomePage),
        content: find.descendant(
          of: find.byType(HomePage),
          matching: find.byType(CustomScrollView),
        ),
        tabName: 'Accueil',
      );

      await tapBottomNav(tester, 'Explorer');
      expectTabClearsBottomNav(
        tester,
        page: find.byType(ExplorerPage),
        content: find.descendant(
          of: find.byType(ExplorerPage),
          matching: find.byType(CustomScrollView),
        ),
        tabName: 'Explorer',
      );

      await tapBottomNav(tester, 'Carte');
      expectTabClearsBottomNav(
        tester,
        page: find.byType(AtlasMapPage),
        content: find
            .descendant(
              of: find.byType(AtlasMapPage),
              matching: find.byType(Center),
            )
            .first,
        tabName: 'Carte',
      );

      await tapBottomNav(tester, 'Démarches');
      expectTabClearsBottomNav(
        tester,
        page: find.byType(ProceduresPage),
        content: find.descendant(
          of: find.byType(ProceduresPage),
          matching: find.byType(CustomScrollView),
        ),
        tabName: 'Démarches',
      );

      await tapBottomNav(tester, 'Prix');
      expectTabClearsBottomNav(
        tester,
        page: find.byType(PricesPage),
        content: find.descendant(
          of: find.byType(PricesPage),
          matching: find.byType(CustomScrollView),
        ),
        tabName: 'Prix',
      );

      await tapBottomNav(tester, 'Profil');
      expectTabClearsBottomNav(
        tester,
        page: find.byType(ProfilePage),
        content: find.descendant(
          of: find.byType(ProfilePage),
          matching: find.byType(ListView),
        ),
        tabName: 'Profil',
      );
    },
  );
}
