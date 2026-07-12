import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/datetime/casablanca_date_formatter.dart';

void main() {
  group('CasablancaDateFormatter', () {
    test('formate une date longue en français', () {
      final label = CasablancaDateFormatter.formatLongDate(
        DateTime(2026, 7, 12),
      );

      expect(label, 'Dimanche 12 juillet 2026');
    });

    test('formate correctement les mois accentués', () {
      final label = CasablancaDateFormatter.formatLongDate(
        DateTime(2026, 2, 3),
      );

      expect(label, 'Mardi 3 février 2026');
    });
  });
}
