import 'dart:convert';

import '../../../../core/network/atlas_http_client.dart';
import 'weather_mapper.dart';
import '../../domain/models/home_models.dart';

/// Client réseau pour l'API Open-Meteo (Marrakech).
class OpenMeteoClient {
  const OpenMeteoClient();

  static const _marrakechLatitude = 31.6295;
  static const _marrakechLongitude = -7.9811;

  static final Uri _forecastUri = Uri.https(
    'api.open-meteo.com',
    '/v1/forecast',
    {
      'latitude': '$_marrakechLatitude',
      'longitude': '$_marrakechLongitude',
      'current': 'temperature_2m,apparent_temperature,weather_code',
      'timezone': 'Africa/Casablanca',
    },
  );

  /// Récupère la météo actuelle pour Marrakech.
  Future<WeatherData> fetchCurrentWeather() async {
    final body = await AtlasHttpClient.get(_forecastUri.toString());
    final json = jsonDecode(body) as Map<String, dynamic>;
    return WeatherMapper.fromOpenMeteo(json);
  }
}
