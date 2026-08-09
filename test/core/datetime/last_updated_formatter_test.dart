import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/datetime/last_updated_formatter.dart';

void main() {
  group('LastUpdatedFormatter', () {
    test('renvoie une chaîne vide sans fetch', () {
      expect(LastUpdatedFormatter.format([]), isEmpty);
    });

    test('renvoie le délai depuis le fetch le plus récent', () {
      final label = LastUpdatedFormatter.format([
        DateTime.now().subtract(const Duration(minutes: 12)),
        DateTime.now().subtract(const Duration(minutes: 3)),
      ]);

      expect(label, 'Toutes les données mises à jour il y a 3 min');
    });
  });
}
