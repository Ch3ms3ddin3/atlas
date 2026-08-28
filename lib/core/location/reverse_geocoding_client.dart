import 'dart:convert';

import '../network/atlas_http_client.dart';

/// Résultat Open-Meteo reverse geocoding.
class ReverseGeocodePlace {
  const ReverseGeocodePlace({required this.cityName, this.countryCode});

  final String cityName;

  /// ISO 3166-1 alpha-2, si fourni par l'API.
  final String? countryCode;
}

/// Reverse geocoding via l'API Open-Meteo (sans clé API).
class ReverseGeocodingClient {
  const ReverseGeocodingClient();

  /// Résout la ville (et le pays si disponible) à partir des coordonnées.
  Future<ReverseGeocodePlace> resolvePlace({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/reverse', {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'language': 'fr',
      'count': '1',
    });

    final body = await AtlasHttpClient.get(uri.toString());
    final json = jsonDecode(body) as Map<String, dynamic>;
    final results = json['results'] as List<dynamic>? ?? [];

    if (results.isEmpty) {
      throw const FormatException('Aucun résultat de géocodage');
    }

    final first = results.first as Map<String, dynamic>;
    final name = first['name'] as String?;
    if (name == null || name.isEmpty) {
      throw const FormatException('Nom de ville manquant');
    }

    final country = (first['country_code'] as String?)?.trim();
    return ReverseGeocodePlace(
      cityName: name,
      countryCode: country == null || country.isEmpty
          ? null
          : country.toUpperCase(),
    );
  }

  /// Résout le nom de ville à partir des coordonnées.
  /// Lance une exception si la requête échoue ou si aucun résultat.
  Future<String> resolveCityName({
    required double latitude,
    required double longitude,
  }) async {
    final place = await resolvePlace(latitude: latitude, longitude: longitude);
    return place.cityName;
  }
}
