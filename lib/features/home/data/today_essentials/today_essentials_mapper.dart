import 'package:flutter/material.dart';

import '../../domain/models/home_models.dart';
import '../mock/home_mock_data.dart';

/// Dérive la section « À savoir aujourd'hui » depuis le contexte live.
abstract final class TodayEssentialsMapper {
  static const _heatThresholdCelsius = 35;

  static TodayEssentialsData fromContext({
    required WeatherData weather,
    required HolidayStatusData holidayStatus,
    required String cityName,
  }) {
    return TodayEssentialsData(
      alert: _buildAlert(
        weather: weather,
        cityName: cityName,
      ),
      tip: _buildTip(
        weather: weather,
        holidayStatus: holidayStatus,
        cityName: cityName,
      ),
      adminReminder: HomeMockData.todayEssentials.adminReminder,
    );
  }

  static AlertData _buildAlert({
    required WeatherData weather,
    required String cityName,
  }) {
    if (weather.temperature >= _heatThresholdCelsius) {
      return AlertData(
        id: 'alert-heat',
        title: 'Forte chaleur prévue',
        detail:
            '${weather.temperature} °C cet après-midi à $cityName — '
            'hydratez-vous et évitez les sorties entre 12h et 16h.',
        source: 'Atlas Météo',
        severity: AlertSeverity.caution,
        icon: Icons.wb_sunny_outlined,
      );
    }

    if (_isRainy(weather)) {
      final isThunder = weather.icon == Icons.thunderstorm_outlined;
      return AlertData(
        id: 'alert-rain',
        title: isThunder ? 'Orages possibles' : 'Pluie prévue',
        detail: isThunder
            ? 'Des orages sont attendus à $cityName — '
                'prenez vos précautions en extérieur.'
            : 'De la pluie est attendue à $cityName — '
                'pensez à un parapluie pour vos déplacements.',
        source: 'Atlas Météo',
        severity: AlertSeverity.caution,
        icon: isThunder
            ? Icons.thunderstorm_outlined
            : Icons.water_drop_outlined,
      );
    }

    return AlertData(
      id: 'alert-weather-info',
      title: weather.condition,
      detail:
          '${weather.temperature} °C à $cityName — '
          'ressenti ${weather.feelsLike} °C.',
      source: 'Atlas Météo',
      severity: AlertSeverity.info,
      icon: weather.icon,
    );
  }

  static DailyInfoData _buildTip({
    required WeatherData weather,
    required HolidayStatusData holidayStatus,
    required String cityName,
  }) {
    if (holidayStatus.isHoliday) {
      return DailyInfoData(
        category: 'Jour férié',
        content:
            'Administrations fermées aujourd\'hui — '
            'planifiez vos démarches demain.',
        icon: Icons.event_busy_outlined,
      );
    }

    if (weather.temperature >= _heatThresholdCelsius) {
      return DailyInfoData(
        category: 'Conseil local',
        content:
            'Visitez $cityName tôt le matin (avant 10h) pour éviter la foule '
            'et profiter des températures plus clémentes.',
        icon: Icons.lightbulb_outline,
      );
    }

    return HomeMockData.todayEssentials.tip;
  }

  static bool _isRainy(WeatherData weather) {
    return weather.icon == Icons.water_drop_outlined ||
        weather.icon == Icons.thunderstorm_outlined ||
        weather.icon == Icons.grain;
  }
}
