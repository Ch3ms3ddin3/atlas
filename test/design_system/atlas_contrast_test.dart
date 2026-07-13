import 'package:atlas/design_system/theme/atlas_colors.dart';
import 'package:atlas/design_system/theme/atlas_contrast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AtlasContrast — WCAG AA', () {
    test('corps de texte : midnightBlue sur warmOffWhite ≥ 7:1', () {
      final ratio = AtlasContrast.ratio(
        AtlasColors.midnightBlue,
        AtlasColors.warmOffWhite,
      );
      expect(ratio, greaterThanOrEqualTo(7.0));
    });

    test('texte secondaire : midnightBlueMuted sur warmOffWhite ≥ 4.5:1', () {
      final ratio = AtlasContrast.ratio(
        AtlasColors.midnightBlueMuted,
        AtlasColors.warmOffWhite,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('bouton : warmOffWhite sur terracotta ≥ 3:1 (labelLarge 14px bold)', () {
      // WCAG AA exige 3:1 pour le texte large (≥14pt gras) — labelLarge des boutons.
      final ratio = AtlasContrast.ratio(
        AtlasColors.warmOffWhite,
        AtlasColors.terracotta,
      );
      expect(ratio, greaterThanOrEqualTo(3.0));
    });

    test('carte : midnightBlue sur surfaceWhite ≥ 7:1', () {
      final ratio = AtlasContrast.ratio(
        AtlasColors.midnightBlue,
        AtlasColors.surfaceWhite,
      );
      expect(ratio, greaterThanOrEqualTo(7.0));
    });

    test('erreur : error sur surfaceWhite ≥ 4.5:1', () {
      final ratio = AtlasContrast.ratio(
        AtlasColors.error,
        AtlasColors.surfaceWhite,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('succès : success sur successMuted ≥ 4.5:1', () {
      final ratio = AtlasContrast.ratio(
        AtlasColors.success,
        AtlasColors.successMuted,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });
}
