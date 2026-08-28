import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/datetime/atlas_display_clock.dart';
import 'package:atlas/core/location/atlas_city_source.dart';

void main() {
  group('AtlasDisplayClock', () {
    test('auto : heure de l\'appareil, pas Casablanca', () {
      final franceLocal = DateTime(2026, 8, 28, 8, 29);
      final clock = AtlasDisplayClock.nowFor(
        citySource: AtlasCitySource.auto,
        deviceNow: franceLocal,
      );
      expect(AtlasDisplayClock.formatHm(clock), '08:29');
      expect(clock, isNot(AtlasDisplayClock.casablancaNow(franceLocal.toUtc())));
    });

    test('manual Marrakech : Africa/Casablanca (UTC+1)', () {
      final utc = DateTime.utc(2026, 8, 28, 6, 29);
      final clock = AtlasDisplayClock.nowFor(
        citySource: AtlasCitySource.manual,
        utcNow: utc,
      );
      expect(AtlasDisplayClock.formatHm(clock), '07:29');
    });

    test('AlAdhan : auto infère les coords, manual force Casablanca', () {
      expect(
        AtlasDisplayClock.aladhanTimeZone(citySource: AtlasCitySource.auto),
        isNull,
      );
      expect(
        AtlasDisplayClock.aladhanTimeZone(citySource: AtlasCitySource.manual),
        'Africa/Casablanca',
      );
    });
  });
}
