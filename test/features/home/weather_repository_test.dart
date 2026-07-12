import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/home/data/weather/weather_mapper.dart';
import 'package:atlas/features/home/data/weather/weather_repository.dart';
import 'package:atlas/features/home/data/weather/open_meteo_client.dart';
import 'package:atlas/features/home/domain/models/home_models.dart';

void main() {
  group('WeatherMapper', () {
    test('mappe une réponse Open-Meteo valide', () {
      final weather = WeatherMapper.fromOpenMeteo({
        'current': {
          'temperature_2m': 36.4,
          'apparent_temperature': 39.8,
          'weather_code': 0,
          'time': DateTime.now().toIso8601String(),
        },
      });

      expect(weather.temperature, 36);
      expect(weather.feelsLike, 40);
      expect(weather.condition, 'Ciel dégagé');
      expect(weather.icon, Icons.wb_sunny_outlined);
      expect(weather.updatedAt, 'à l\'instant');
    });
  });

  group('WeatherRepository', () {
    test('retombe sur le mock si l\'API échoue', () async {
      final repository = WeatherRepository(
        client: _FailingOpenMeteoClient(),
      );

      final weather = await repository.getWeather(
        latitude: 31.6295,
        longitude: -7.9811,
      );

      expect(weather.temperature, 38);
      expect(weather.condition, 'Très ensoleillé');
      expect(weather.feelsLike, 41);
      expect(weather.updatedAt, 'données estimées');
    });
  });
}

class _FailingOpenMeteoClient extends OpenMeteoClient {
  @override
  Future<WeatherData> fetchCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    throw Exception('network error');
  }
}
