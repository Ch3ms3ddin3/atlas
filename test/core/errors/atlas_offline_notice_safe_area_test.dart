import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/errors/atlas_error_ui.dart';
import 'package:atlas/core/network/atlas_connectivity.dart';

/// Miroir du chrome AppShell (SafeArea + removePadding) pour tests ciblés.
class _OfflineBannerHost extends StatelessWidget {
  const _OfflineBannerHost({required this.isOffline, required this.showBeta});

  final bool isOffline;
  final bool showBeta;

  @override
  Widget build(BuildContext context) {
    final hasTopChrome = showBeta || isOffline;
    return Column(
      children: [
        if (showBeta)
          const ColoredBox(
            color: Colors.blue,
            child: SizedBox(height: 24, width: double.infinity),
          ),
        if (isOffline)
          SafeArea(
            top: !showBeta,
            bottom: false,
            left: false,
            right: false,
            child: const AtlasOfflineNotice(),
          ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: hasTopChrome,
            removeBottom: true,
            child: const ColoredBox(
              color: Colors.green,
              child: Align(
                alignment: Alignment.topCenter,
                child: Text('home-content'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void main() {
  testWidgets('AtlasOfflineNotice under SafeArea starts below the top inset', (
    tester,
  ) async {
    const topInset = 59.0;

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          padding: EdgeInsets.only(top: topInset),
          viewPadding: EdgeInsets.only(top: topInset),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SafeArea(
                  bottom: false,
                  left: false,
                  right: false,
                  child: AtlasOfflineNotice(),
                ),
                Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.byType(AtlasOfflineNotice)).dy, topInset);
    expect(find.textContaining('Hors ligne — Atlas continue'), findsOneWidget);
  });

  testWidgets(
    'bandeau visible hors-ligne et retiré à la reconnexion sans grand vide',
    (tester) async {
      const topInset = 59.0;
      final connectivity = AtlasConnectivity(interpretResults: (_) => false);
      addTearDown(connectivity.dispose);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(top: topInset),
            viewPadding: EdgeInsets.only(top: topInset),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: ListenableBuilder(
                listenable: connectivity,
                builder: (context, _) {
                  return _OfflineBannerHost(
                    isOffline: connectivity.isOffline,
                    showBeta: false,
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AtlasOfflineNotice), findsNothing);
      final onlineTop = tester.getTopLeft(find.text('home-content')).dy;

      connectivity.debugSetOffline(true);
      await tester.pumpAndSettle();

      expect(find.byType(AtlasOfflineNotice), findsOneWidget);
      expect(tester.getTopLeft(find.byType(AtlasOfflineNotice)).dy, topInset);
      expect(
        tester.getTopLeft(find.text('home-content')).dy,
        greaterThan(topInset),
      );

      connectivity.debugSetOffline(false);
      await tester.pumpAndSettle();

      expect(find.byType(AtlasOfflineNotice), findsNothing);
      expect(tester.getTopLeft(find.text('home-content')).dy, onlineTop);
    },
  );
}
