import 'package:atlas/features/prices/presentation/widgets/prices_scroll_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('masqué quand le contenu ne défile pas', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: Stack(
              children: [
                ListView(
                  controller: controller,
                  children: const [SizedBox(height: 100, child: Text('short'))],
                ),
                PricesScrollProgressIndicator(controller: controller),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = tester.state<PricesScrollProgressIndicatorState>(
      find.byType(PricesScrollProgressIndicator),
    );
    expect(state.debugScrollable, isFalse);
    expect(find.byType(DecoratedBox), findsNothing);
  });

  testWidgets('apparaît au scroll et suit le progrès clampé', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ListView.builder(
                  controller: controller,
                  itemCount: 40,
                  itemBuilder: (_, i) =>
                      SizedBox(height: 80, child: Text('row $i')),
                ),
                PricesScrollProgressIndicator(controller: controller),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = tester.state<PricesScrollProgressIndicatorState>(
      find.byType(PricesScrollProgressIndicator),
    );
    expect(state.debugScrollable, isTrue);
    expect(state.debugProgress, 0);

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pump();
    expect(state.debugVisible, isTrue);
    expect(state.debugProgress, greaterThan(0));
    expect(state.debugProgress, lessThanOrEqualTo(1));

    // Overscroll bounce must not push progress outside [0, 1].
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pump();
    expect(state.debugProgress, 1.0);

    await tester.drag(find.byType(ListView), const Offset(0, 8000));
    await tester.pump();
    expect(state.debugProgress, 0.0);
  });
}
