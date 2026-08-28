import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/location/atlas_city_source.dart';
import 'package:atlas/features/profile/domain/models/user_profile.dart';

void main() {
  group('AtlasCitySource.inferLegacy', () {
    test('clé absente + Marrakech → auto', () {
      expect(
        AtlasCitySource.inferLegacy(
          preferredCity: 'Marrakech',
          defaultPreferredCity: UserProfile.defaultPreferredCity,
        ),
        AtlasCitySource.auto,
      );
    });

    test('clé absente + Fès → manual (vrai choix passé)', () {
      expect(
        AtlasCitySource.inferLegacy(
          preferredCity: 'Fès',
          defaultPreferredCity: UserProfile.defaultPreferredCity,
        ),
        AtlasCitySource.manual,
      );
    });

    test('valeur stockée auto gagne sur Fès', () {
      expect(
        AtlasCitySource.inferLegacy(
          preferredCity: 'Fès',
          defaultPreferredCity: UserProfile.defaultPreferredCity,
          stored: 'auto',
        ),
        AtlasCitySource.auto,
      );
    });

    test('valeur stockée manual gagne sur Marrakech', () {
      expect(
        AtlasCitySource.inferLegacy(
          preferredCity: 'Marrakech',
          defaultPreferredCity: UserProfile.defaultPreferredCity,
          stored: 'manual',
        ),
        AtlasCitySource.manual,
      );
    });
  });
}
