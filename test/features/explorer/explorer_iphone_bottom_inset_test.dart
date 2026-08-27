import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/editorial/editorial_repository_bootstrap.dart';
import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/design_system/theme/atlas_spacing.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/explorer/domain/place_repository.dart';
import 'package:atlas/features/explorer/presentation/pages/explorer_page.dart';
import 'package:atlas/features/explorer/presentation/widgets/place_guide_card.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';
import 'package:atlas/features/shell/presentation/shell_navigation_scope.dart';
import 'package:atlas/features/shell/presentation/shell_tab_scroll_registry.dart';

/// Hors shell, Explorer doit encore respecter le home indicator via SafeArea.
const _iphoneSize = Size(390, 844);
const _iphoneTopInset = 47.0;
const _iphoneBottomInset = 34.0;

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

  testWidgets('sans shell: SafeArea conserve l\'inset iOS en bas de liste', (
    tester,
  ) async {
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

    final profile = LocalProfileRepository();
    final favorites = LocalFavoritesRepository();
    await profile.load();
    await favorites.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: ProfileScope(
          repository: profile,
          child: FavoritesScope(
            repository: favorites,
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

    final scrollView = tester.widget<CustomScrollView>(
      find.byType(CustomScrollView),
    );
    scrollView.controller!.jumpTo(
      scrollView.controller!.position.maxScrollExtent,
    );
    await tester.pumpAndSettle();

    final list = tester.getRect(find.byType(CustomScrollView));
    expect(
      list.bottom,
      lessThanOrEqualTo(_iphoneSize.height - _iphoneBottomInset + 0.5),
    );

    final cardFinder = find.byType(PlaceGuideCard);
    expect(cardFinder, findsWidgets);

    var lowestCardBottom = 0.0;
    for (final element in cardFinder.evaluate()) {
      final bottom = tester.getRect(find.byWidget(element.widget)).bottom;
      if (bottom > lowestCardBottom) lowestCardBottom = bottom;
    }

    expect(
      lowestCardBottom,
      lessThanOrEqualTo(list.bottom - AtlasSpacing.lg + 1.0),
    );
  });
}
