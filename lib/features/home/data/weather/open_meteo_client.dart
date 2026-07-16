import 'dart:convert';

import '../../../../core/network/atlas_http_client.dart';
import '../../domain/models/home_models.dart';
import 'weather_mapper.dart';

/// Client réseau pour l'API Open-Meteo.
class OpenMeteoClient {
  const OpenMeteoClient();

  /// Récupère la météo actuelle pour les coordonnées données (Africa/Casablanca).
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
        'current':
            'temperature_2m,apparent_temperature,weather_code,wind_speed_10m',
        'hourly': 'precipitation_probability,uv_index',
        'forecast_days': '1',
        'timezone': 'Africa/Casablanca',
      },
    );

    final body = await AtlasHttpClient.get(uri.toString());
    final json = jsonDecode(body) as Map<String, dynamic>;
    return WeatherMapper.fromOpenMeteo(json);
  }
}
