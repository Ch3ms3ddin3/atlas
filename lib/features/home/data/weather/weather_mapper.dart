import 'package:flutter/material.dart';

import '../../domain/models/home_models.dart';

/// Convertit la réponse Open-Meteo en [WeatherData] affichable.
abstract final class WeatherMapper {
  /// Mapping strict — lève si température / ressenti / code absents.
  static WeatherData fromOpenMeteo(
    Map<String, dynamic> json, {
    DateTime? fetchedAt,
  }) {
    final current = json['current'];
    if (current is! Map) {
      throw const FormatException('Réponse Open-Meteo sans bloc current');
    }

    final weatherCode = _asInt(current['weather_code']);
    if (weatherCode == null) {
      throw const FormatException('weather_code manquant');
    }

    final temperature = _roundTemperature(current['temperature_2m']);
    final feelsLike = _roundTemperature(current['apparent_temperature']);
    if (temperature == null || feelsLike == null) {
      throw const FormatException('températures manquantes');
    }

    final observedAtIso = current['time'] as String?;
    final hourlyMetrics = _hourlyMetrics(json, observedAtIso);

    return WeatherData(
      temperature: temperature,
      feelsLike: feelsLike,
      condition: conditionLabel(weatherCode),
      icon: iconForCode(weatherCode),
      weatherCode: weatherCode,
      fetchedAt: fetchedAt ?? DateTime.now(),
      observedAtIso: observedAtIso,
      windKmh: _optionalNonNegativeDouble(current['wind_speed_10m']),
      uvIndex: hourlyMetrics.uvIndex,
      rainProbabilityPercent: hourlyMetrics.rainProbabilityPercent,
    );
  }

  static String conditionLabel(int code) {
    return switch (code) {
      0 => 'Ciel dégagé',
      1 => 'Peu nuageux',
      2 => 'Partiellement nuageux',
      3 => 'Couvert',
      45 || 48 => 'Brouillard',
      51 || 53 || 55 => 'Bruine',
      56 || 57 => 'Bruine verglaçante',
      61 || 63 || 65 => 'Pluie',
      66 || 67 => 'Pluie verglaçante',
      71 || 73 || 75 => 'Neige',
      77 => 'Grains de neige',
      80 || 81 || 82 => 'Averses',
      85 || 86 => 'Averses de neige',
      95 => 'Orage',
      96 || 99 => 'Orage avec grêle',
      _ => 'Conditions variables',
    };
  }

  static IconData iconForCode(int code) {
    return switch (code) {
      0 || 1 => Icons.wb_sunny_outlined,
      2 || 3 => Icons.wb_cloudy_outlined,
      45 || 48 => Icons.foggy,
      51 || 53 || 55 || 56 || 57 => Icons.grain,
      61 || 63 || 65 || 66 || 67 || 80 || 81 || 82 => Icons.water_drop_outlined,
      71 || 73 || 75 || 77 || 85 || 86 => Icons.ac_unit_outlined,
      95 || 96 || 99 => Icons.thunderstorm_outlined,
      _ => Icons.wb_cloudy_outlined,
    };
  }

  static int? _roundTemperature(dynamic value) {
    if (value is num) return value.round();
    if (value is String) return double.tryParse(value)?.round();
    return null;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _optionalNonNegativeDouble(dynamic value) {
    if (value == null) return null;
    final parsed = value is num
        ? value.toDouble()
        : value is String
            ? double.tryParse(value)
            : null;
    if (parsed == null || parsed.isNaN || parsed < 0) return null;
    return parsed;
  }

  static ({double? uvIndex, int? rainProbabilityPercent}) _hourlyMetrics(
    Map<String, dynamic> json,
    String? observedAtIso,
  ) {
    final hourly = json['hourly'];
    if (hourly is! Map) {
      return (uvIndex: null, rainProbabilityPercent: null);
    }

    final times = hourly['time'];
    if (times is! List || times.isEmpty) {
      return (uvIndex: null, rainProbabilityPercent: null);
    }

    var index = 0;
    if (observedAtIso != null && observedAtIso.isNotEmpty) {
      final match = times.indexWhere((item) => item.toString() == observedAtIso);
      if (match >= 0) {
        index = match;
      } else {
        // Prend l'heure la plus proche / première future si exact match absent.
        index = 0;
        final observed = DateTime.tryParse(observedAtIso);
        if (observed != null) {
          for (var i = 0; i < times.length; i++) {
            final t = DateTime.tryParse(times[i].toString());
            if (t != null && !t.isBefore(observed)) {
              index = i;
              break;
            }
          }
        }
      }
    }

    final uvList = hourly['uv_index'];
    final rainList = hourly['precipitation_probability'];

    double? uv;
    if (uvList is List && index < uvList.length) {
      uv = _optionalNonNegativeDouble(uvList[index]);
    }

    int? rain;
    if (rainList is List && index < rainList.length) {
      final value = _asInt(rainList[index]);
      if (value != null && value >= 0 && value <= 100) {
        rain = value;
      }
    }

    return (uvIndex: uv, rainProbabilityPercent: rain);
  }
}
