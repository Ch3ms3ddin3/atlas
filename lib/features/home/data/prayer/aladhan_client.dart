import 'dart:convert';

import '../../../../core/network/atlas_http_client.dart';
import 'prayer_mapper.dart';

/// Client réseau pour l'API AlAdhan (méthode Maroc).
class AladhanClient {
  const AladhanClient();

  static const _moroccoMethod = 21;

  /// Récupère les horaires du jour pour les coordonnées données (Africa/Casablanca).
  Future<Map<String, String>> fetchTodayTimings({
    required double latitude,
    required double longitude,
  }) async {
    final now = PrayerMapper.casablancaNow();
    final date = '${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.year}';

    final uri = Uri.https(
      'api.aladhan.com',
      '/v1/timings/$date',
      {
        'latitude': '$latitude',
        'longitude': '$longitude',
        'method': '$_moroccoMethod',
        'timezonestring': 'Africa/Casablanca',
      },
    );

    final body = await AtlasHttpClient.get(uri.toString());
    final json = jsonDecode(body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final timings = data['timings'] as Map<String, dynamic>? ?? {};

    return {
      for (final name in PrayerMapper.prayerNames)
        name: _normalizeTime(timings[name] as String? ?? ''),
    };
  }

  static String _normalizeTime(String raw) {
    // L'API peut renvoyer "13:43 (GMT+1)" — on ne garde que HH:mm.
    final match = RegExp(r'(\d{1,2}:\d{2})').firstMatch(raw);
    return match?.group(1) ?? raw;
  }
}
