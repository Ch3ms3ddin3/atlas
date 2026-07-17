import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/design_system/motion/atlas_haptics.dart';
import 'package:atlas/design_system/theme/atlas_motion.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/design_system/widgets/atlas_fade_switcher.dart';
import 'package:atlas/design_system/widgets/atlas_reveal.dart';
import 'package:atlas/design_system/widgets/atlas_skeleton.dart';

void main() {
  testWidgets('reduce motion: reveal and switcher show content immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          theme: AtlasTheme.light,
          home: Scaffold(
            body: Column(
              children: [
                AtlasReveal(
                  child: Text('revealed', key: const Key('revealed')),
                ),
                AtlasFadeSwitcher(
                  child: Text('ready', key: const Key('ready')),
                ),
                const AtlasSkeleton(key: Key('skeleton'), height: 12, width: 80),
              ],
            ),
          ),
        ),
      ),
    );

    // Pas besoin de pumpAndSettle — contenu visible immédiatement.
    expect(find.byKey(const Key('revealed')), findsOneWidget);
    expect(find.byKey(const Key('ready')), findsOneWidget);
    expect(find.byKey(const Key('skeleton')), findsOneWidget);
    expect(AtlasMotion.reduceMotionOf(tester.element(find.byType(Scaffold))), isTrue);
  });

  test('haptics no-op safely without throwing', () async {
    await AtlasHaptics.selection();
    await AtlasHaptics.light();
    await AtlasHaptics.primaryAction();
  });
}
