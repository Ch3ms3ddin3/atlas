import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/data/place_catalog.dart';
import 'package:atlas/features/explorer/data/place_mapper.dart';
import 'package:atlas/features/explorer/domain/models/place_models.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/map/data/map_place_query.dart';
import 'package:atlas/features/map/data/map_search_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaceBrowseFilters.resetForTest();
  });

  tearDown(PlaceBrowseFilters.resetForTest);

  List<PlaceGuide> search(
    String text, {
    String city = 'Marrakech',
    PlaceCategory? category,
  }) {
    return PlaceMapper.filter(
      PlaceSearchQuery(
        text: text,
        cityName: city,
        category: category,
        strictCity: true,
      ),
    );
  }

  group('MapSearchText relevance', () {
    test('name prefix outranks summary-only French filler', () {
      expect(
        MapSearchText.relevanceRank(
          query: 'plus',
          name: 'Plus61',
          summary: 'Bistro',
          neighborhood: 'Guéliz',
          categoryLabel: 'Restaurant',
        ),
        0,
      );
      expect(
        MapSearchText.relevanceRank(
          query: 'plus',
          name: 'Palais de la Bahia',
          summary: 'la visite la plus claire',
          neighborhood: 'Médina',
          categoryLabel: 'Monument',
        ),
        3,
      );
    });

    test('token prefix matches mid-name words', () {
      expect(
        MapSearchText.relevanceRank(
          query: 'youss',
          name: 'Médersa Ben Youssef',
          summary: 'Résumé',
          neighborhood: 'Médina',
          categoryLabel: 'Monument',
        ),
        0,
      );
      expect(
        MapSearchText.relevanceRank(
          query: 'majo',
          name: 'Jardin Majorelle',
          summary: 'Résumé',
          neighborhood: 'Guéliz',
          categoryLabel: 'Jardin',
        ),
        0,
      );
    });
  });

  group('Explorer global partial search', () {
    test('plus finds Plus61 first — not only exact Plus61', () {
      final partial = search('plus');
      final plus6 = search('plus6');
      final sixtyOne = search('61');
      final exact = search('Plus61');
      final upper = search('PLUS');

      expect(partial.map((p) => p.id), contains('place-plus61'));
      expect(partial.first.id, 'place-plus61');
      expect(plus6.first.id, 'place-plus61');
      expect(sixtyOne.map((p) => p.id), contains('place-plus61'));
      expect(exact.map((p) => p.id), ['place-plus61']);
      expect(upper.first.id, 'place-plus61');

      final plus61 = PlaceCatalog.guides.firstWhere(
        (p) => p.id == 'place-plus61',
      );
      expect(plus61.isEditorsPick, isFalse);
    });

    test('alphanumeric / +alias names match via runs and slug', () {
      const plusAlias = PlaceGuide(
        id: 'place-plus61',
        name: '+61',
        cityName: 'Marrakech',
        category: PlaceCategory.restaurant,
        categoryLabel: 'Restaurant',
        neighborhood: 'Guéliz',
        priceLevel: '€€€',
        isEditorsPick: false,
        imageColor: Color(0xFF3D5A4C),
        summary: 'Alias display name without the word plus.',
        practicalTips: [],
        latitude: 31.635162,
        longitude: -8.015502,
      );
      const cafe22 = PlaceGuide(
        id: 'place-cafe22-test',
        name: 'Cafe22',
        cityName: 'Marrakech',
        category: PlaceCategory.cafe,
        categoryLabel: 'Café',
        neighborhood: 'Guéliz',
        priceLevel: '€',
        isEditorsPick: false,
        imageColor: Color(0xFF3D5A4C),
        summary: 'Synthetic alphanumeric café.',
        practicalTips: [],
        latitude: 31.63,
        longitude: -8.01,
      );

      expect(
        MapSearchText.placeMatches(
          query: 'plus',
          name: plusAlias.name,
          summary: plusAlias.summary,
          neighborhood: plusAlias.neighborhood,
          categoryLabel: plusAlias.categoryLabel,
          placeId: plusAlias.id,
        ),
        isTrue,
      );
      expect(MapSearchText.alphanumericRuns('Plus61'), ['plus', '61']);
      expect(MapSearchText.slugSearchTail('place-plus61'), 'plus61');

      final aliased = PlaceMapper.filter(
        const PlaceSearchQuery(
          text: 'plus',
          cityName: 'Marrakech',
          strictCity: true,
        ),
        source: const [plusAlias, cafe22],
      );
      expect(aliased.map((p) => p.id), contains('place-plus61'));
      expect(aliased.first.id, 'place-plus61');

      final cafeHits = PlaceMapper.filter(
        const PlaceSearchQuery(
          text: 'cafe',
          cityName: 'Marrakech',
          strictCity: true,
        ),
        source: const [plusAlias, cafe22],
      );
      expect(cafeHits.map((p) => p.id), ['place-cafe22-test']);
      expect(
        PlaceMapper.filter(
          const PlaceSearchQuery(
            text: '22',
            cityName: 'Marrakech',
            strictCity: true,
          ),
          source: const [plusAlias, cafe22],
        ).map((p) => p.id),
        contains('place-cafe22-test'),
      );
    });

    test('majo finds Jardin Majorelle via partial name', () {
      final places = search('majo');
      expect(places.map((p) => p.id), contains('place-majorelle'));
      expect(places.first.id, 'place-majorelle');
    });

    test('youss finds Médersa Ben Youssef mid-name', () {
      final places = search('youss');
      expect(places.map((p) => p.id), contains('place-medersa-ben-youssef'));
      expect(places.first.id, 'place-medersa-ben-youssef');
    });

    test('bacha surfaces Bacha Coffee and Dar El Bacha', () {
      final places = search('bacha');
      final ids = places.map((p) => p.id).toSet();
      expect(ids, contains('place-bacha-coffee'));
      expect(ids, contains('place-musee-dar-el-bacha'));
      expect(
        places.take(2).map((p) => p.id).toSet(),
        containsAll(['place-bacha-coffee', 'place-musee-dar-el-bacha']),
      );
    });

    test('nom finds Nomad via partial name', () {
      final places = search('nom');
      expect(places.map((p) => p.id), contains('place-nomad'));
      expect(places.first.id, 'place-nomad');
    });

    test('case and accent equivalence', () {
      expect(search('MAJO').map((p) => p.id), contains('place-majorelle'));
      expect(
        search('médersa').map((p) => p.id),
        contains('place-medersa-ben-youssef'),
      );
      expect(
        search('MEDERSA').map((p) => p.id),
        contains('place-medersa-ben-youssef'),
      );
    });

    test('full exact names still work', () {
      expect(
        search('Jardin Majorelle').map((p) => p.id),
        contains('place-majorelle'),
      );
      expect(search('Plus61').map((p) => p.id), contains('place-plus61'));
      expect(search('Nomad').map((p) => p.id), contains('place-nomad'));
    });

    test('unrelated queries do not return unrelated places', () {
      final places = search('zzzzzz-atlas-no-match');
      expect(places, isEmpty);

      final plage = search('plage');
      expect(plage.any((p) => p.id == 'place-plus61'), isFalse);
      expect(plage.any((p) => p.id == 'place-majorelle'), isFalse);
    });

    test('non-curated places remain searchable', () {
      for (final id in const [
        'place-plus61',
        'place-sahbi-sahbi',
        'place-kartell-kollektiv',
        'place-simple-specialty-coffee',
      ]) {
        final place = PlaceCatalog.guides.firstWhere((p) => p.id == id);
        expect(place.isEditorsPick, isFalse);
        final needle = place.name.split(RegExp(r'\s+')).first;
        final hits = search(
          needle.length >= 4 ? needle.substring(0, 4) : needle,
        );
        expect(
          hits.map((p) => p.id),
          contains(id),
          reason: 'partial "$needle" should find $id',
        );
      }
    });

    test('selected city filtering still works', () {
      final marrakech = search('hassan', city: 'Marrakech');
      expect(marrakech.every((p) => p.cityName == 'Marrakech'), isTrue);
      expect(marrakech.any((p) => p.id == 'place-hassan-ii'), isFalse);

      final casa = search('hassan', city: 'Casablanca');
      expect(casa.map((p) => p.id), contains('place-hassan-ii'));
      expect(casa.every((p) => p.cityName == 'Casablanca'), isTrue);
    });

    test('Carte shares name-first partial ranking', () {
      final filters = PlaceBrowseFilters.instance
        ..setCityName('Marrakech', notify: false)
        ..setSearchText('plus', notify: false);
      final markers = MapPlaceQuery.markers(
        repository: LocalPlaceRepository(),
        filters: filters,
      );
      expect(markers, isNotEmpty);
      expect(markers.first.placeId, 'place-plus61');
    });
  });
}
