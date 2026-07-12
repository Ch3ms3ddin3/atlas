import 'package:flutter/material.dart';

import '../../domain/models/home_models.dart';

/// Convertit la réponse Open-Meteo en [WeatherData] affichable.
abstract final class WeatherMapper {
  static WeatherData fromOpenMeteo(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final weatherCode = current['weather_code'] as int? ?? 0;
    final updatedAt = _formatUpdatedAt(current['time'] as String?);

    return WeatherData(
      temperature: _roundTemperature(current['temperature_2m']),
      feelsLike: _roundTemperature(current['apparent_temperature']),
      condition: _conditionLabel(weatherCode),
      icon: _iconForCode(weatherCode),
      updatedAt: updatedAt,
    );
  }

  static int _roundTemperature(dynamic value) {
    if (value is num) {
      return value.round();
    }
    return 0;
  }

  static String _formatUpdatedAt(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty) {
      return 'à l\'instant';
    }

    try {
      final observedAt = DateTime.parse(isoTime);
      final difference = DateTime.now().difference(observedAt);

      if (difference.inMinutes < 1) {
        return 'à l\'instant';
      }
      if (difference.inMinutes < 60) {
        return 'il y a ${difference.inMinutes} min';
      }
      if (difference.inHours < 24) {
        return 'il y a ${difference.inHours} h';
      }
      return 'il y a ${difference.inDays} j';
    } on FormatException {
      return 'à l\'instant';
    }
  }

  static String _conditionLabel(int code) {
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

  static IconData _iconForCode(int code) {
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
}
