import 'dart:convert';

import '../../../core/network/atlas_http_client.dart';

/// Prévision journalière Open-Meteo (multi-jours).
class DailyWeatherForecast {
  const DailyWeatherForecast({
    required this.date,
    required this.tempMaxC,
    required this.tempMinC,
    required this.weatherCode,
    this.precipitationProbabilityMax,
  });

  final DateTime date;
  final double tempMaxC;
  final double tempMinC;
  final int weatherCode;
  final int? precipitationProbabilityMax;

  String get summaryLabel {
    final rain = precipitationProbabilityMax;
    final rainPart = rain != null && rain >= 40 ? ', pluie possible ($rain%)' : '';
    return '${tempMinC.round()}–${tempMaxC.round()}°C$rainPart';
  }
}

/// Extension multi-jours pour la planification d'itinéraires.
class OpenMeteoDailyForecastClient {
  const OpenMeteoDailyForecastClient();

  Future<List<DailyWeatherForecast>> fetchDailyForecast({
    required double latitude,
    required double longitude,
    int forecastDays = 7,
  }) async {
    final days = forecastDays.clamp(1, 14);
    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': '$latitude',
        'longitude': '$longitude',
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
        'forecast_days': '$days',
        'timezone': 'Africa/Casablanca',
      },
    );

    final body = await AtlasHttpClient.get(uri.toString());
    final json = jsonDecode(body) as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>?;
    if (daily == null) return const [];

    final times = (daily['time'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    final maxes = daily['temperature_2m_max'] as List<dynamic>? ?? const [];
    final mins = daily['temperature_2m_min'] as List<dynamic>? ?? const [];
    final codes = daily['weather_code'] as List<dynamic>? ?? const [];
    final rains =
        daily['precipitation_probability_max'] as List<dynamic>? ?? const [];

    final result = <DailyWeatherForecast>[];
    for (var i = 0; i < times.length; i++) {
      final parsed = DateTime.tryParse(times[i]);
      if (parsed == null) continue;
      result.add(
        DailyWeatherForecast(
          date: DateTime(parsed.year, parsed.month, parsed.day),
          tempMaxC: (maxes[i] as num?)?.toDouble() ?? 0,
          tempMinC: (mins[i] as num?)?.toDouble() ?? 0,
          weatherCode: (codes[i] as num?)?.toInt() ?? 0,
          precipitationProbabilityMax: i < rains.length
              ? (rains[i] as num?)?.toInt()
              : null,
        ),
      );
    }
    return result;
  }
}
