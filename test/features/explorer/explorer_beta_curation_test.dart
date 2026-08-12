import 'package:atlas/core/location/morocco_cities.dart';
import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/data/place_catalog.dart';
import 'package:atlas/features/explorer/data/place_mapper.dart';
import 'package:atlas/features/explorer/domain/models/place_models.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/map/data/map_place_query.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaceBrowseFilters.resetForTest();
  });

  tearDown(PlaceBrowseFilters.resetForTest);

  test('Marrakech beta core is exactly 18 editorial picks', () {
    expect(PlaceCatalog.marrakechBetaCoreIds, hasLength(18));
    expect(PlaceCatalog.marrakechBetaCoreIds.contains('place-macaal'), isTrue);

    final marrakech = PlaceCatalog.guides.where(
      (p) => p.cityName == 'Marrakech',
    );
    expect(marrakech, hasLength(31));

    final picks = marrakech.where((p) => p.isEditorsPick).toList();
    expect(picks, hasLength(18));
    expect(picks.map((p) => p.id).toSet(), PlaceCatalog.marrakechBetaCoreIds);

    final demoted = marrakech.where((p) => !p.isEditorsPick).toList();
    expect(demoted, hasLength(13));
    expect(
      demoted
          .map((p) => p.id)
          .toSet()
          .intersection(PlaceCatalog.marrakechBetaCoreIds),
      isEmpty,
    );
  });

  test('default Ordre Atlas keeps demoted places discoverable', () {
    final repo = LocalPlaceRepository();
    final all = repo.search(
      const PlaceSearchQuery(
        cityName: 'Marrakech',
        sort: PlaceSort.catalog,
        strictCity: true,
      ),
    );
    expect(all, hasLength(31));
    expect(all.first.id, 'place-jemaa-el-fna');
    expect(all.any((p) => p.id == 'place-plus61'), isTrue);
    expect(all.any((p) => p.id == 'place-simple-specialty-coffee'), isTrue);

    final search = repo.search(
      const PlaceSearchQuery(
        text: 'plus61',
        cityName: 'Marrakech',
        sort: PlaceSort.catalog,
        strictCity: true,
      ),
    );
    expect(search.map((p) => p.id), contains('place-plus61'));
  });

  test('Explorer and Carte share covered-city browsing set', () {
    final repo = LocalPlaceRepository();
    final covered = [
      for (final name in MoroccoCities.supportedNames)
        if (repo.isCityCovered(name)) name,
    ];
    expect(covered, ['Marrakech', 'Casablanca', 'Rabat']);
    expect(covered, isNot(contains('Fès')));
    expect(covered, isNot(contains('Tanger')));
    expect(covered, isNot(contains('Agadir')));

    final filters = PlaceBrowseFilters.instance
      ..setCityName('Marrakech', notify: false);
    final markers = MapPlaceQuery.markers(repository: repo, filters: filters);
    expect(markers.length, 31);
    expect(markers.any((m) => m.placeId == 'place-jemaa-el-fna'), isTrue);
    expect(markers.any((m) => m.placeId == 'place-plus61'), isTrue);
  });

  test('category mix of beta core matches approved distribution', () {
    final byCategory = <PlaceCategory, int>{};
    for (final id in PlaceCatalog.marrakechBetaCoreIds) {
      final place = PlaceCatalog.guides.firstWhere((p) => p.id == id);
      byCategory[place.category] = (byCategory[place.category] ?? 0) + 1;
    }
    expect(byCategory[PlaceCategory.monument], 5);
    expect(byCategory[PlaceCategory.musee], 4);
    expect(byCategory[PlaceCategory.cafe], 3);
    expect(byCategory[PlaceCategory.restaurant], 3);
    expect(byCategory[PlaceCategory.hammam], 1);
    expect(byCategory[PlaceCategory.jardin], 1);
    expect(byCategory[PlaceCategory.souk], 1);
  });

  test('PlaceMapper catalog sort is editorial partition only', () {
    final places = PlaceMapper.filter(
      const PlaceSearchQuery(cityName: 'Marrakech', sort: PlaceSort.catalog),
    );
    // No invented popularity fields — only isEditorsPick + stable order.
    expect(places.every((p) => p.priceLevel.isNotEmpty), isTrue);
    expect(places.first.isEditorsPick, isTrue);
  });
}
