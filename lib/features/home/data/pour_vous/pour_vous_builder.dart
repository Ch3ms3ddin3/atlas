import 'package:flutter/material.dart';

import '../../domain/models/weather_snapshot.dart';
import '../prayer/prayer_mapper.dart';

/// Recommandation contextuelle affichée dans « Pour vous ».
class PourVousRecommendation {
  const PourVousRecommendation({
    required this.message,
    required this.icon,
  });

  final String message;
  final IconData icon;

  /// Titre court si le message contient un séparateur « — ».
  String get title {
    final parts = message.split(' — ');
    return parts.first.trim();
  }

  /// Texte de soutien optionnel.
  String? get detail {
    final parts = message.split(' — ');
    if (parts.length < 2) return null;
    return parts.sublist(1).join(' — ').trim();
  }
}

/// Suggestions contextuelles — max 2, jamais de contenu de remplissage.
class PourVousBuilder {
  const PourVousBuilder();

  static const _maxItems = 2;

  List<PourVousRecommendation> build({
    required WeatherSnapshot weatherSnapshot,
    required String cityName,
  }) {
    final now = PrayerMapper.casablancaNow();
    final recommendations = <PourVousRecommendation>[];

    final weather = weatherSnapshot.data;
    if (weatherSnapshot.hasWeather && weather != null) {
      if (weather.temperature >= 32) {
        recommendations.add(
          const PourVousRecommendation(
            icon: Icons.wb_sunny_outlined,
            message:
                'Forte chaleur — hydratez-vous et évitez le plein soleil à midi.',
          ),
        );
      } else if (weather.temperature >= 18 &&
          weather.temperature <= 28 &&
          weather.weatherCode <= 1) {
        recommendations.add(
          const PourVousRecommendation(
            icon: Icons.wb_twilight_outlined,
            message: 'Belle fenêtre météo — idéale pour une sortie en ville.',
          ),
        );
      }
    }

    if (now.weekday == DateTime.friday) {
      recommendations.add(
        const PourVousRecommendation(
          icon: Icons.description_outlined,
          message:
              'Vendredi — anticipez vos démarches avant la pause du milieu de journée.',
        ),
      );
    } else if (now.weekday == DateTime.thursday) {
      recommendations.add(
        const PourVousRecommendation(
          icon: Icons.schedule_outlined,
          message: 'Jeudi — certains guichets ferment plus tôt demain.',
        ),
      );
    }

    if (recommendations.length < _maxItems &&
        cityName.toLowerCase().contains('marrakech')) {
      recommendations.add(
        const PourVousRecommendation(
          icon: Icons.park_outlined,
          message:
              'Jardin Majorelle — réservez tôt si vous souhaitez y aller aujourd\'hui.',
        ),
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        const PourVousRecommendation(
          icon: Icons.badge_outlined,
          message:
              'Pièce d\'identité — gardez votre CIN ou passeport à portée.',
        ),
      );
    }

    return recommendations.take(_maxItems).toList();
  }
}
