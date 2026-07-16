import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/features/home/data/weather/open_meteo_client.dart';
import 'package:atlas/features/home/data/weather/weather_cache_store.dart';
import 'package:atlas/features/home/data/weather/weather_mapper.dart';
import 'package:atlas/features/home/data/weather/weather_repository.dart';
import 'package:atlas/features/home/domain/models/home_models.dart';
import 'package:atlas/features/home/domain/models/weather_snapshot.dart';

class _FakeOpenMeteoClient extends OpenMeteoClient {
  _FakeOpenMeteoClient({
    this.fail = false,
    this.payload,
  });

  bool fail;
  Map<String, dynamic>? payload;
  var callCount = 0;
  double? lastLatitude;
  double? lastLongitude;

  @override
  Future<WeatherData> fetchCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    callCount += 1;
    lastLatitude = latitude;
    lastLongitude = longitude;
    if (fail) throw Exception('network error');
    return WeatherMapper.fromOpenMeteo(
      payload ??
          {
            'current': {
              'temperature_2m': 36.4,
              'apparent_temperature': 39.8,
              'weather_code': 0,
              'wind_speed_10m': 12.4,
              'time': '2026-07-15T14:00',
            },
            'hourly': {
              'time': ['2026-07-15T14:00'],
              'uv_index': [8.2],
              'precipitation_probability': [20],
            },
          },
    );
  }
}

Map<String, dynamic> _payload({
  required int weatherCode,
  double temperature = 24.2,
  double feelsLike = 25.1,
  double? wind,
  List<dynamic>? uv,
  List<dynamic>? rain,
}) {
  return {
    'current': {
      'temperature_2m': temperature,
      'apparent_temperature': feelsLike,
      'weather_code': weatherCode,
      'wind_speed_10m': ?wind,
      'time': '2026-07-15T14:00',
    },
    'hourly': {
      'time': ['2026-07-15T14:00'],
      'uv_index': ?uv,
      'precipitation_probability': ?rain,
    },
  };
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WeatherMapper', () {
    test('succès live : température, ressenti et condition', () {
      final weather = WeatherMapper.fromOpenMeteo(_payload(
        weatherCode: 0,
        temperature: 36.4,
        feelsLike: 39.8,
        wind: 12.4,
        uv: [8.2],
        rain: [20],
      ));

      expect(weather.temperature, 36);
      expect(weather.feelsLike, 40);
      expect(weather.condition, 'Ciel dégagé');
      expect(weather.icon, Icons.wb_sunny_outlined);
      expect(weather.weatherCode, 0);
      expect(weather.windKmh, 12.4);
      expect(weather.uvIndex, 8.2);
      expect(weather.rainProbabilityPercent, 20);
      expect(weather.lastUpdatedLabel, contains('Mis à jour'));
    });

    test('mappe les codes météo vers icônes et libellés FR', () {
      expect(WeatherMapper.conditionLabel(0), 'Ciel dégagé');
      expect(WeatherMapper.iconForCode(0), Icons.wb_sunny_outlined);

      expect(WeatherMapper.conditionLabel(3), 'Couvert');
      expect(WeatherMapper.iconForCode(3), Icons.wb_cloudy_outlined);

      expect(WeatherMapper.conditionLabel(61), 'Pluie');
      expect(WeatherMapper.iconForCode(61), Icons.water_drop_outlined);

      expect(WeatherMapper.conditionLabel(95), 'Orage');
      expect(WeatherMapper.iconForCode(95), Icons.thunderstorm_outlined);

      expect(WeatherMapper.conditionLabel(71), 'Neige');
      expect(WeatherMapper.iconForCode(71), Icons.ac_unit_outlined);
    });

    test('n\'expose que les métriques optionnelles fiables', () {
      final withMetrics = WeatherMapper.fromOpenMeteo(_payload(
        weatherCode: 2,
        wind: 10,
        uv: [3.5],
        rain: [40],
      ));
      expect(withMetrics.hasWind, isTrue);
      expect(withMetrics.hasUv, isTrue);
      expect(withMetrics.hasRainProbability, isTrue);

      final withoutMetrics = WeatherMapper.fromOpenMeteo(_payload(
        weatherCode: 2,
      ));
      expect(withoutMetrics.hasWind, isFalse);
      expect(withoutMetrics.hasUv, isFalse);
      expect(withoutMetrics.hasRainProbability, isFalse);

      final invalidRain = WeatherMapper.fromOpenMeteo(_payload(
        weatherCode: 2,
        wind: -1,
        uv: [-2],
        rain: [150],
      ));
      expect(invalidRain.hasWind, isFalse);
      expect(invalidRain.hasUv, isFalse);
      expect(invalidRain.hasRainProbability, isFalse);
    });

    test('refuse une réponse incomplète', () {
      expect(
        () => WeatherMapper.fromOpenMeteo({
          'current': {'weather_code': 0},
        }),
        throwsFormatException,
      );
    });
  });

  group('WeatherRepository', () {
    test('succès live : snapshot success et mise en cache', () async {
      final client = _FakeOpenMeteoClient();
      final repository = WeatherRepository(client: client);

      final snapshot = await repository.getWeather(
        latitude: 31.6295,
        longitude: -7.9811,
      );

      expect(snapshot.state, WeatherLoadState.success);
      expect(snapshot.data!.temperature, 36);
      expect(snapshot.data!.condition, 'Ciel dégagé');
      expect(snapshot.statusLabel, 'Open-Meteo');
      expect(client.callCount, 1);
    });

    test('échec sans cache : unavailable (pas de météo inventée)', () async {
      final repository = WeatherRepository(
        client: _FakeOpenMeteoClient(fail: true),
      );

      final snapshot = await repository.getWeather(
        latitude: 31.6295,
        longitude: -7.9811,
      );

      expect(snapshot.state, WeatherLoadState.unavailable);
      expect(snapshot.data, isNull);
      expect(snapshot.hasWeather, isFalse);
    });

    test('échec avec cache : stale et observation enregistrée', () async {
      const store = WeatherCacheStore();
      await store.save(
        latitude: 31.6295,
        longitude: -7.9811,
        data: WeatherData(
          temperature: 33,
          feelsLike: 35,
          condition: 'Peu nuageux',
          icon: Icons.wb_sunny_outlined,
          weatherCode: 1,
          fetchedAt: DateTime(2026, 7, 14, 12),
          windKmh: 8,
        ),
      );

      final repository = WeatherRepository(
        client: _FakeOpenMeteoClient(fail: true),
        cacheStore: store,
      );

      final snapshot = await repository.getWeather(
        latitude: 31.6295,
        longitude: -7.9811,
      );

      expect(snapshot.state, WeatherLoadState.stale);
      expect(snapshot.data!.temperature, 33);
      expect(snapshot.data!.condition, 'Peu nuageux');
      expect(snapshot.statusLabel, 'Météo enregistrée');
    });

    test('changement de ville : cache d\'une autre ville non réutilisé', () async {
      const store = WeatherCacheStore();
      await store.save(
        latitude: 31.6295,
        longitude: -7.9811,
        data: const WeatherData(
          temperature: 38,
          feelsLike: 41,
          condition: 'Ciel dégagé',
          icon: Icons.wb_sunny_outlined,
          weatherCode: 0,
        ),
      );

      final repository = WeatherRepository(
        client: _FakeOpenMeteoClient(fail: true),
        cacheStore: store,
      );

      final otherCity = await repository.getWeather(
        latitude: 33.5731,
        longitude: -7.5898,
      );

      expect(otherCity.state, WeatherLoadState.unavailable);
      expect(otherCity.data, isNull);

      final sameCity = await repository.getWeather(
        latitude: 31.6295,
        longitude: -7.9811,
      );
      expect(sameCity.state, WeatherLoadState.stale);
      expect(sameCity.data!.temperature, 38);
    });

    test('rafraîchissement manuel refetch le réseau', () async {
      final client = _FakeOpenMeteoClient(
        payload: _payload(weatherCode: 0, temperature: 30, feelsLike: 31),
      );
      final repository = WeatherRepository(client: client);

      await repository.getWeather(latitude: 31.63, longitude: -7.98);
      expect(client.callCount, 1);

      client.payload = _payload(weatherCode: 61, temperature: 22, feelsLike: 21);
      final refreshed = await repository.getWeather(
        latitude: 31.63,
        longitude: -7.98,
      );

      expect(client.callCount, 2);
      expect(refreshed.state, WeatherLoadState.success);
      expect(refreshed.data!.temperature, 22);
      expect(refreshed.data!.condition, 'Pluie');
      expect(client.lastLatitude, 31.63);
      expect(client.lastLongitude, -7.98);
    });
  });
}
