import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/prices/presentation/widgets/price_city_selector.dart';

void main() {
  testWidgets('shows only data cities, not the full MoroccoCities list', (
    tester,
  ) async {
    String? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PriceCitySelector(
            selectedCity: 'Marrakech',
            dataCities: const ['Marrakech', 'Casablanca', 'Rabat'],
            onCitySelected: (city) => tapped = city,
          ),
        ),
      ),
    );

    expect(find.text('Marrakech'), findsOneWidget);
    expect(find.text('Casablanca'), findsOneWidget);
    expect(find.text('Rabat'), findsOneWidget);
    expect(find.text('Fès'), findsNothing);
    expect(find.text('Tanger'), findsNothing);
    expect(find.text('Agadir'), findsNothing);

    await tester.tap(find.text('Rabat'));
    expect(tapped, 'Rabat');
  });

  testWidgets('keeps selected city visible even if absent from dataCities', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PriceCitySelector(
            selectedCity: 'Fès',
            dataCities: const ['Marrakech'],
            onCitySelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Fès'), findsOneWidget);
    expect(find.text('Marrakech'), findsOneWidget);
    expect(find.text('Tanger'), findsNothing);
  });
}
