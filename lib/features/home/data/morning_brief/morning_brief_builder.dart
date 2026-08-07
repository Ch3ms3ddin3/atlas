import '../../../events/domain/models/atlas_event.dart';
import '../../domain/models/exchange_rate_snapshot.dart';
import '../../domain/models/prayer_times_snapshot.dart';
import '../../domain/models/weather_snapshot.dart';
import '../prayer/prayer_mapper.dart';

/// Ligne scannable du briefing matinal.
class MorningBriefLine {
  const MorningBriefLine({
    required this.emoji,
    required this.text,
  });

  final String emoji;
  final String text;
}

/// Résumé dynamique « Aujourd'hui à {ville} » — lisible en moins de 5 secondes.
class MorningBriefData {
  const MorningBriefData({
    required this.title,
    required this.lines,
    this.isLoading = false,
  });

  final String title;
  final List<MorningBriefLine> lines;
  final bool isLoading;

  static MorningBriefData loading({required String cityName}) {
    return MorningBriefData(
      title: 'Aujourd\'hui à $cityName',
      lines: const [],
      isLoading: true,
    );
  }
}

/// Compose le briefing à partir des snapshots live — jamais de données inventées.
class MorningBriefBuilder {
  const MorningBriefBuilder();

  MorningBriefData build({
    required String cityName,
    required WeatherSnapshot weatherSnapshot,
    required PrayerTimesSnapshot prayerSnapshot,
    required ExchangeRateSnapshot exchangeRateSnapshot,
    required List<AtlasEvent> todayEvents,
  }) {
    final anyLoading = weatherSnapshot.state == WeatherLoadState.loading ||
        prayerSnapshot.state == PrayerLoadState.loading ||
        exchangeRateSnapshot.state == ExchangeRateLoadState.loading;

    if (anyLoading) {
      return MorningBriefData.loading(cityName: cityName);
    }

    return MorningBriefData(
      title: 'Aujourd\'hui à $cityName',
      lines: [
        _weatherLine(weatherSnapshot),
        _prayerLine(prayerSnapshot),
        _exchangeLine(exchangeRateSnapshot),
        _trafficLine(),
        _eventsLine(todayEvents),
      ],
    );
  }

  MorningBriefLine _weatherLine(WeatherSnapshot snapshot) {
    return switch (snapshot.state) {
      WeatherLoadState.success || WeatherLoadState.stale => MorningBriefLine(
          emoji: _weatherEmoji(snapshot.data!.weatherCode),
          text: '${snapshot.data!.temperature}°C',
        ),
      _ => const MorningBriefLine(
          emoji: '☁️',
          text: 'Météo indisponible',
        ),
    };
  }

  MorningBriefLine _prayerLine(PrayerTimesSnapshot snapshot) {
    return switch (snapshot.state) {
      PrayerLoadState.success || PrayerLoadState.stale => MorningBriefLine(
          emoji: '🕌',
          text:
              '${snapshot.data!.nextPrayerName} ${snapshot.data!.nextPrayerCountdown}',
        ),
      _ => const MorningBriefLine(
          emoji: '🕌',
          text: 'Horaires indisponibles',
        ),
    };
  }

  MorningBriefLine _exchangeLine(ExchangeRateSnapshot snapshot) {
    return switch (snapshot.state) {
      ExchangeRateLoadState.success || ExchangeRateLoadState.stale =>
        MorningBriefLine(
          emoji: '💶',
          text:
              '1 ${snapshot.data!.fromCurrency} = ${snapshot.data!.rate.toStringAsFixed(2)} ${snapshot.data!.toCurrency}',
        ),
      _ => const MorningBriefLine(
          emoji: '💶',
          text: 'Taux indisponible',
        ),
    };
  }

  /// Circulation — mock intelligent en attendant une source fiable.
  MorningBriefLine _trafficLine() {
    final hour = PrayerMapper.casablancaNow().hour;
    if (hour >= 7 && hour <= 9 || hour >= 17 && hour <= 19) {
      return const MorningBriefLine(
        emoji: '🚦',
        text: 'Circulation dense aux heures de pointe',
      );
    }
    return const MorningBriefLine(
      emoji: '🚦',
      text: 'Circulation fluide',
    );
  }

  MorningBriefLine _eventsLine(List<AtlasEvent> todayEvents) {
    if (todayEvents.isEmpty) {
      return const MorningBriefLine(
        emoji: '🎉',
        text: 'Aucun événement majeur',
      );
    }
    if (todayEvents.length == 1) {
      return MorningBriefLine(
        emoji: '🎉',
        text: todayEvents.first.title,
      );
    }
    return MorningBriefLine(
      emoji: '🎉',
      text: '${todayEvents.length} événements aujourd\'hui',
    );
  }

  String _weatherEmoji(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '🌤️';
    if (code <= 48) return '🌫️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '🌨️';
    if (code <= 82) return '🌦️';
    if (code <= 99) return '⛈️';
    return '🌡️';
  }
}
