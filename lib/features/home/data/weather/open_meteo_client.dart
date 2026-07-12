import 'dart:convert';

import '../../../../core/network/atlas_http_client.dart';
import 'weather_mapper.dart';
import '../../domain/models/home_models.dart';

/// Client réseau pour l'API Open-Meteo.
class OpenMeteoClient {
  const OpenMeteoClient();

  /// Récupère la météo actuelle pour les coordonnées données.
  Future<WeatherData> fetchCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': '$latitude',
        'longitude': '$longitude',
        'current': 'temperature_2m,apparent_temperature,weather_code',
        'timezone': 'Africa/Casablanca',
      },
    );

    final body = await AtlasHttpClient.get(uri.toString());
    final json = jsonDecode(body) as Map<String, dynamic>;
    return WeatherMapper.fromOpenMeteo(json);
  }
}
