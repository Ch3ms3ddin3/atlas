import 'dart:convert';

import '../network/atlas_http_client.dart';

/// Reverse geocoding via l'API Open-Meteo (sans clé API).
class ReverseGeocodingClient {
  const ReverseGeocodingClient();

  /// Résout le nom de ville à partir des coordonnées.
  /// Lance une exception si la requête échoue ou si aucun résultat.
  Future<String> resolveCityName({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'geocoding-api.open-meteo.com',
      '/v1/reverse',
      {
        'latitude': '$latitude',
        'longitude': '$longitude',
        'language': 'fr',
        'count': '1',
      },
    );

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

    return name;
  }
}
