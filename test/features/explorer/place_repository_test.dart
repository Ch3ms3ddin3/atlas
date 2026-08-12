import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/data/place_catalog.dart';
import 'package:atlas/features/explorer/data/place_mapper.dart';
import 'package:atlas/features/explorer/domain/models/place_models.dart';

void main() {
  group('PlaceMapper', () {
    test('filtre par ville', () {
      final places = PlaceMapper.filter(
        const PlaceSearchQuery(cityName: 'Casablanca'),
      );

      expect(places, isNotEmpty);
      expect(places.every((place) => place.cityName == 'Casablanca'), isTrue);
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
        const PlaceSearchQuery(cityName: 'Rabat', text: 'oudayas'),
      );

      expect(places.any((place) => place.id == 'place-oudayas'), isTrue);
    });

    test('retombe sur Marrakech pour une ville inconnue', () {
      expect(PlaceMapper.resolveCityName('Tanger'), 'Marrakech');
    });

    test('strictCity conserve une ville non couverte et renvoie vide', () {
      final places = PlaceMapper.filter(
        const PlaceSearchQuery(cityName: 'Tanger', strictCity: true),
      );

      expect(places, isEmpty);
    });

    test(
      'le tri catalog place les sélections en tête sans réordonner le groupe',
      () {
        final scrambled = [
          PlaceCatalog.guides.firstWhere((p) => p.id == 'place-plus61'),
          PlaceCatalog.guides.firstWhere((p) => p.id == 'place-jemaa-el-fna'),
          PlaceCatalog.guides.firstWhere((p) => p.id == 'place-sahbi-sahbi'),
          PlaceCatalog.guides.firstWhere((p) => p.id == 'place-majorelle'),
        ];
        final sorted = PlaceMapper.sortPlaces(scrambled, PlaceSort.catalog);
        expect(sorted.map((p) => p.id).toList(), [
          'place-jemaa-el-fna',
          'place-majorelle',
          'place-plus61',
          'place-sahbi-sahbi',
        ]);
        expect(sorted.take(2).every((p) => p.isEditorsPick), isTrue);
        expect(sorted.skip(2).every((p) => !p.isEditorsPick), isTrue);
      },
    );

    test('le tri catalog filtre Marrakech avec le cœur éditorial en tête', () {
      final sorted = PlaceMapper.filter(
        const PlaceSearchQuery(cityName: 'Marrakech', sort: PlaceSort.catalog),
      );

      expect(sorted, isNotEmpty);
      expect(sorted.first.isEditorsPick, isTrue);
      final firstNonPick = sorted.indexWhere((place) => !place.isEditorsPick);
      expect(firstNonPick, greaterThan(0));
      expect(
        sorted.take(firstNonPick).every((place) => place.isEditorsPick),
        isTrue,
      );
      expect(
        sorted.skip(firstNonPick).every((place) => !place.isEditorsPick),
        isTrue,
      );
      expect(sorted.where((p) => p.isEditorsPick), hasLength(18));
    });

    test('le tri nameAsc ordonne alphabétiquement', () {
      final places = PlaceMapper.filter(
        const PlaceSearchQuery(cityName: 'Marrakech', sort: PlaceSort.nameAsc),
      );

      final names = places.map((place) => place.name).toList();
      expect(names, List<String>.from(names)..sort());
    });

    test('le tri editorsPick place les sélections en tête', () {
      final places = PlaceMapper.filter(
        const PlaceSearchQuery(
          cityName: 'Marrakech',
          sort: PlaceSort.editorsPick,
        ),
      );

      expect(places.first.isEditorsPick, isTrue);
      final firstNonPick = places.indexWhere((place) => !place.isEditorsPick);
      if (firstNonPick != -1) {
        expect(
          places.skip(firstNonPick).every((place) => !place.isEditorsPick),
          isTrue,
        );
      }
    });
  });

  group('LocalPlaceRepository', () {
    final repository = LocalPlaceRepository();

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
