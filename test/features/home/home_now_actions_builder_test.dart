import 'package:atlas/core/location/location_constants.dart';
import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/domain/place_repository.dart';
import 'package:atlas/features/home/data/now_actions/home_now_actions_builder.dart';
import 'package:atlas/features/home/domain/models/home_models.dart';
import 'package:atlas/features/home/domain/models/weather_snapshot.dart';
import 'package:atlas/features/prices/data/price_observation_catalog.dart';
import 'package:atlas/features/prices/domain/models/price_observation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    PlaceRepository.resetForTest();
    PlaceRepository.registerFactory(LocalPlaceRepository.new);
  });

  tearDown(PlaceRepository.resetForTest);

  const builder = HomeNowActionsBuilder();

  WeatherSnapshot weatherAt(int tempC) {
    return WeatherSnapshot(
      state: WeatherLoadState.success,
      data: WeatherData(
        temperature: tempC,
        feelsLike: tempC,
        condition: 'Ciel dégagé',
        icon: Icons.wb_sunny_outlined,
        weatherCode: 0,
        fetchedAt: DateTime(2026, 8, 12, 16),
      ),
    );
  }

  test('Marrakech: SIM + visite + carte (max 3)', () {
    final actions = builder.build(
      cityName: LocationConstants.fallbackCity,
      weatherSnapshot: weatherAt(38),
      priceSource: PriceObservationCatalog.asObservations,
      placeRepository: PlaceRepository(),
      referenceTime: DateTime(2026, 8, 12, 16),
    );

    expect(actions.length, inInclusiveRange(1, 3));
    expect(actions.any((a) => a.kind == HomeNowActionKind.price), isTrue);
    expect(actions.any((a) => a.kind == HomeNowActionKind.place), isTrue);
    expect(actions.any((a) => a.kind == HomeNowActionKind.map), isTrue);
    expect(
      actions.where((a) => a.kind == HomeNowActionKind.place).single.title,
      'Visite à couvert',
    );
    expect(
      actions.every((a) => !a.subtitle.toLowerCase().contains('taxi')),
      isTrue,
    );
  });

  test('Casablanca: pas de visite Marrakech, SIM national OK', () {
    final actions = builder.build(
      cityName: 'Casablanca',
      weatherSnapshot: weatherAt(28),
      priceSource: PriceObservationCatalog.asObservations,
      placeRepository: PlaceRepository(),
    );

    expect(actions.any((a) => a.kind == HomeNowActionKind.place), isFalse);
    expect(actions.any((a) => a.kind == HomeNowActionKind.price), isTrue);
    expect(actions.every((a) => !a.subtitle.contains('Majorelle')), isTrue);
    expect(actions.every((a) => !a.subtitle.contains('Bahia')), isTrue);
  });

  test('sans prix ni lieux couverts: section vide', () {
    final actions = builder.build(
      cityName: 'Agadir',
      weatherSnapshot: weatherAt(25),
      priceSource: const <PriceObservation>[],
      placeRepository: PlaceRepository(),
    );
    expect(actions, isEmpty);
  });
}
