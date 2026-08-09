import 'package:flutter/material.dart';

import '../../../events/domain/models/atlas_event.dart';
import '../../domain/models/weather_snapshot.dart';
import '../prayer/prayer_mapper.dart';

/// Une seule intuition utile — affichée seulement s'il y a un signal réel.
class DailyInsightData {
  const DailyInsightData({
    required this.message,
    this.icon = Icons.lightbulb_outline,
  });

  final String message;
  final IconData icon;

  String get title {
    final parts = message.split(' — ');
    return parts.first.trim();
  }

  String? get detail {
    final parts = message.split(' — ');
    if (parts.length < 2) return null;
    return parts.sublist(1).join(' — ').trim();
  }
}

/// Compose au plus un conseil contextualisé — jamais de filler.
///
/// Signaux acceptés : météo live, jour de semaine (vendredi), événement du jour.
/// Retourne `null` s'il n'y a rien d'utile à dire.
class DailyInsightBuilder {
  const DailyInsightBuilder();

  DailyInsightData? build({
    required WeatherSnapshot weatherSnapshot,
    required String cityName,
    List<AtlasEvent> todayEvents = const [],
  }) {
    final now = PrayerMapper.casablancaNow();
    final weather = weatherSnapshot.data;

    if (weatherSnapshot.hasWeather && weather != null) {
      if (weather.temperature >= 34) {
        return const DailyInsightData(
          icon: Icons.wb_sunny_outlined,
          message:
              'Chaleur intense — privilégiez l\'ombre et hydratez-vous régulièrement.',
        );
      }
      if (weather.hasRainProbability &&
          weather.rainProbabilityPercent != null &&
          weather.rainProbabilityPercent! >= 50) {
        return const DailyInsightData(
          icon: Icons.umbrella_outlined,
          message:
              'Pluie possible — un plan B à couvert peut être utile cet après-midi.',
        );
      }
      if (weather.temperature >= 18 &&
          weather.temperature <= 26 &&
          weather.weatherCode <= 1 &&
          now.hour >= 16) {
        return const DailyInsightData(
          icon: Icons.wb_twilight_outlined,
          message: 'Fin de journée clémente — idéal pour une balade au calme.',
        );
      }
    }

    if (now.weekday == DateTime.friday) {
      return const DailyInsightData(
        icon: Icons.schedule_outlined,
        message:
            'Vendredi — certains commerces ferment plus tôt autour de la prière.',
      );
    }

    if (todayEvents.isNotEmpty) {
      final first = todayEvents.first;
      if (todayEvents.length == 1) {
        return DailyInsightData(
          icon: Icons.event_outlined,
          message: 'Aujourd\'hui — ${first.title}.',
        );
      }
      return DailyInsightData(
        icon: Icons.event_outlined,
        message:
            'Aujourd\'hui — ${todayEvents.length} dates utiles listées dans l\'agenda.',
      );
    }

    // Pas de signal météo / calendrier / agenda → masquer la section.
    return null;
  }
}
