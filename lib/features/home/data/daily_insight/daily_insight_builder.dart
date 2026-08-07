import '../prayer/prayer_mapper.dart';
import '../../domain/models/weather_snapshot.dart';

/// Une seule intuition utile — « Bon à savoir ».
class DailyInsightData {
  const DailyInsightData({required this.message});

  final String message;
}

/// Compose un insight discret — jamais de données inventées.
class DailyInsightBuilder {
  const DailyInsightBuilder();

  DailyInsightData build({
    required WeatherSnapshot weatherSnapshot,
    required String cityName,
  }) {
    final now = PrayerMapper.casablancaNow();
    final weather = weatherSnapshot.data;

    if (weatherSnapshot.hasWeather && weather != null) {
      if (weather.temperature >= 34) {
        return const DailyInsightData(
          message:
              'Chaleur intense — privilégiez l\'ombre et hydratez-vous régulièrement.',
        );
      }
      if (weather.hasRainProbability &&
          weather.rainProbabilityPercent != null &&
          weather.rainProbabilityPercent! >= 50) {
        return const DailyInsightData(
          message:
              'Pluie possible — un plan B à couvert peut être utile cet après-midi.',
        );
      }
      if (weather.temperature >= 18 &&
          weather.temperature <= 26 &&
          weather.weatherCode <= 1 &&
          now.hour >= 16) {
        return const DailyInsightData(
          message:
              'Fin de journée clémente — idéal pour une balade au calme.',
        );
      }
    }

    if (now.weekday == DateTime.friday) {
      return const DailyInsightData(
        message:
            'Vendredi — certains commerces ferment plus tôt autour de la prière.',
      );
    }

    if (cityName.toLowerCase().contains('marrakech') && now.hour < 12) {
      return const DailyInsightData(
        message:
            'Les jardins et musées sont souvent plus agréables en matinée.',
      );
    }

    return const DailyInsightData(
      message:
          'Gardez une pièce d\'identité sur vous lors de vos déplacements.',
    );
  }
}
