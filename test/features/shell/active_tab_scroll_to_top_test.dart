import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/app/atlas_app.dart';
import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/features/admission_temporaire/data/at_bootstrap.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/explorer/presentation/pages/explorer_page.dart';
import 'package:atlas/features/map/presentation/widgets/atlas_flutter_map_view.dart';
import 'package:atlas/features/prices/domain/price_intelligence_repository.dart';
import 'package:atlas/features/prices/presentation/pages/prices_page.dart';
import 'package:atlas/features/shell/presentation/atlas_bottom_nav.dart';
import 'package:atlas/features/shell/presentation/shell_navigation_scope.dart';
import 'package:atlas/features/shell/presentation/shell_tab_scroll_registry.dart';

import '../onboarding/onboarding_test_helpers.dart';
import '../prices/price_intelligence_test_helpers.dart';

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
  }

  Future<void> pumpAtlasApp(WidgetTester tester) async {
    await tester.pumpWidget(const AtlasApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  }

  ShellTabScrollRegistry registryOf(WidgetTester tester) {
    return tester
        .widget<ShellNavigationScope>(find.byType(ShellNavigationScope))
        .scrollRegistry;
  }

  testWidgets('Explorer active-tab retap scrolls to top and preserves search', (
    tester,
  ) async {
    await pumpAtlasApp(tester);
    await tapBottomNav(tester, 'Explorer');

    final searchFields = find.descendant(
      of: find.byType(ExplorerPage),
      matching: find.byType(TextField),
    );
    await tester.enterText(searchFields.first, 'Majorelle');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    final controller = registryOf(
      tester,
    ).controllerForTest(AtlasShellTab.explorer);
    expect(controller, isNotNull);
    expect(controller!.hasClients, isTrue);

    final target = controller.position.maxScrollExtent.clamp(120.0, 600.0);
    controller.jumpTo(target);
    await tester.pump();
    expect(controller.offset, greaterThan(80));

    final cityBefore = PlaceBrowseFilters.instance.cityName;
    await tapBottomNav(tester, 'Explorer');

    expect(controller.offset, lessThan(8));
    expect(find.text('Majorelle'), findsWidgets);
    expect(PlaceBrowseFilters.instance.cityName, cityBefore);
    expect(PlaceBrowseFilters.instance.searchText, 'Majorelle');
  });

  testWidgets('Prix active-tab retap scrolls to top without resetting page', (
    tester,
  ) async {
    await pumpAtlasApp(tester);
    await tapBottomNav(tester, 'Prix');

    final controller = registryOf(
      tester,
    ).controllerForTest(AtlasShellTab.prices);
    expect(controller, isNotNull);
    expect(controller!.hasClients, isTrue);

    final maxExtent = controller.position.maxScrollExtent;
    if (maxExtent > 40) {
      controller.jumpTo(maxExtent.clamp(40, 400));
      await tester.pump();
      expect(controller.offset, greaterThan(20));
    }

    await tapBottomNav(tester, 'Prix');
    expect(controller.offset, lessThan(8));
    expect(find.byType(PricesPage), findsOneWidget);
    expect(find.text('Prix'), findsWidgets);
  });

  testWidgets('switching tabs still behaves normally', (tester) async {
    await pumpAtlasApp(tester);

    await tapBottomNav(tester, 'Explorer');
    expect(find.byType(ExplorerPage), findsOneWidget);

    await tapBottomNav(tester, 'Prix');
    expect(find.byType(PricesPage), findsOneWidget);

    await tapBottomNav(tester, 'Accueil');
    expect(find.textContaining('Aujourd\'hui'), findsWidgets);
  });

  testWidgets('scroll-to-top does not pop a pushed detail route', (
    tester,
  ) async {
    await pumpAtlasApp(tester);
    await tapBottomNav(tester, 'Explorer');

    final registry = registryOf(tester);
    final explorerContext = tester.element(find.byType(ExplorerPage));
    Navigator.of(explorerContext).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            const Scaffold(body: Center(child: Text('DETAIL_ROUTE_PROBE'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('DETAIL_ROUTE_PROBE'), findsOneWidget);

    await registry.scrollToTop(AtlasShellTab.explorer);
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('DETAIL_ROUTE_PROBE'), findsOneWidget);
  });

  test(
    'ShellTabScrollRegistry near-top / missing controller is a no-op',
    () async {
      final registry = ShellTabScrollRegistry();
      final controller = ScrollController();
      registry.register(AtlasShellTab.explorer, controller);

      await registry.scrollToTop(AtlasShellTab.explorer);

      registry.unregister(AtlasShellTab.explorer, controller);
      expect(registry.controllerForTest(AtlasShellTab.explorer), isNull);
      controller.dispose();
    },
  );
}
