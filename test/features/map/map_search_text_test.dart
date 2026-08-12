import 'package:atlas/features/map/data/map_search_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapSearchText.normalize', () {
    test('strips French diacritics and lowercases', () {
      expect(MapSearchText.normalize('Musée'), 'musee');
      expect(MapSearchText.normalize('musée'), 'musee');
      expect(MapSearchText.normalize('MUSEE'), 'musee');
      expect(MapSearchText.normalize('Médina'), 'medina');
      expect(MapSearchText.normalize('guéliz'), 'gueliz');
      expect(MapSearchText.normalize('  Ça  '), 'ca');
    });

    test('does not alter already plain text', () {
      expect(MapSearchText.normalize('musee'), 'musee');
      expect(MapSearchText.normalize('medina'), 'medina');
    });

    test('matchesQuery is accent and case insensitive', () {
      final haystack = MapSearchText.searchableHaystack(
        name: 'Musée Yves Saint Laurent',
        summary: 'Musée dédié à Yves Saint Laurent',
        neighborhood: 'Guéliz',
        categoryLabel: 'Musée',
      );
      expect(haystack, contains('musee'));
      expect(haystack, contains('gueliz'));
      expect(MapSearchText.matchesQuery('musee', haystack), isTrue);
      expect(MapSearchText.matchesQuery('MUSÉE', haystack), isTrue);
      expect(MapSearchText.matchesQuery('gueliz', haystack), isTrue);
      expect(MapSearchText.matchesQuery('plage', haystack), isFalse);
    });

    test('placeMatches supports progressive name prefixes', () {
      expect(
        MapSearchText.placeMatches(
          query: 'plus',
          name: 'Plus61',
          summary: 'Bistro',
          neighborhood: 'Guéliz',
          categoryLabel: 'Restaurant',
          placeId: 'place-plus61',
        ),
        isTrue,
      );
      expect(
        MapSearchText.placeMatches(
          query: 'plus',
          name: '+61',
          summary: 'Sans le mot plus dans le résumé.',
          neighborhood: 'Guéliz',
          categoryLabel: 'Restaurant',
          placeId: 'place-plus61',
        ),
        isTrue,
      );
      expect(
        MapSearchText.placeMatches(
          query: 'youss',
          name: 'Médersa Ben Youssef',
          summary: 'Résumé sans le mot',
          neighborhood: 'Médina',
          categoryLabel: 'Monument',
        ),
        isTrue,
      );
    });
  });
}
