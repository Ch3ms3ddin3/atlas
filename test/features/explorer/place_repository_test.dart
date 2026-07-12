import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/explorer/data/place_catalog.dart';
import 'package:atlas/features/explorer/data/place_mapper.dart';
import 'package:atlas/features/explorer/data/place_repository.dart';
import 'package:atlas/features/explorer/domain/models/place_models.dart';

void main() {
  group('PlaceMapper', () {
    test('filtre par ville', () {
      final places = PlaceMapper.filter(
        const PlaceSearchQuery(cityName: 'Casablanca'),
      );

      expect(places, isNotEmpty);
      expect(
        places.every((place) => place.cityName == 'Casablanca'),
        isTrue,
      );
    });

    test('filtre par catégorie', () {
      final places = PlaceMapper.filter(
        const PlaceSearchQuery(
          cityName: 'Marrakech',
          category: PlaceCategory.jardin,
        ),
      );

      expect(places.any((place) => place.id == 'place-majorelle'), isTrue);
      expect(
        places.every((place) => place.category == PlaceCategory.jardin),
        isTrue,
      );
    });

    test('recherche par nom ou quartier', () {
      final places = PlaceMapper.filter(
        const PlaceSearchQuery(
          cityName: 'Rabat',
          text: 'oudayas',
        ),
      );

      expect(places.any((place) => place.id == 'place-oudayas'), isTrue);
    });

    test('retombe sur Marrakech pour une ville inconnue', () {
      expect(
        PlaceMapper.resolveCityName('Tanger'),
        'Marrakech',
      );
    });
  });

  group('PlaceRepository', () {
    const repository = PlaceRepository();

    test('expose au moins 12 lieux au total', () {
      expect(PlaceCatalog.guides.length, greaterThanOrEqualTo(12));
    });

    test('retourne les sélections Atlas pour une ville', () {
      final featured = repository.getFeatured(cityName: 'Marrakech');

      expect(featured, isNotEmpty);
      expect(featured.every((place) => place.isEditorsPick), isTrue);
    });

    test('retrouve un lieu par identifiant', () {
      final place = repository.findById('place-majorelle');

      expect(place, isNotNull);
      expect(place!.name, 'Jardin Majorelle');
    });

    test('détecte une ville non couverte', () {
      expect(repository.isCityCovered('Tanger'), isFalse);
      expect(repository.isCityCovered('Marrakech'), isTrue);
    });

    test('convertit vers RecommendedPlaceData', () {
      final place = repository.findById('place-bahia')!;
      final recommended = PlaceMapper.toRecommendedPlaceData(place);

      expect(recommended.id, 'place-bahia');
      expect(recommended.distanceLabel, 'Médina');
    });
  });
}
