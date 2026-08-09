import '../../../events/domain/models/atlas_event.dart';
import '../../domain/models/exchange_rate_snapshot.dart';
import '../../domain/models/prayer_times_snapshot.dart';
import '../../domain/models/weather_snapshot.dart';

/// Identifiant d'action optionnel pour une ligne du briefing.
enum MorningBriefAction { events }

/// Ligne scannable du briefing matinal.
class MorningBriefLine {
  const MorningBriefLine({
    required this.emoji,
    required this.text,
    this.action,
  });

  final String emoji;
  final String text;

  /// Si non null, la ligne peut ouvrir une surface Atlas (ex. agenda).
  final MorningBriefAction? action;
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
///
/// Pas de circulation mock. Agenda affiché seulement s'il y a des dates listées.
class MorningBriefBuilder {
  const MorningBriefBuilder();

  MorningBriefData build({
    required String cityName,
    required WeatherSnapshot weatherSnapshot,
    required PrayerTimesSnapshot prayerSnapshot,
    required ExchangeRateSnapshot exchangeRateSnapshot,
    required List<AtlasEvent> todayEvents,
  }) {
    // Weather + prayer gate the brief; FX may still be loading as its own line.
    final coreLoading =
        weatherSnapshot.state == WeatherLoadState.loading ||
        prayerSnapshot.state == PrayerLoadState.loading;

    if (coreLoading) {
      return MorningBriefData.loading(cityName: cityName);
    }

    final lines = <MorningBriefLine>[
      _weatherLine(weatherSnapshot),
      _prayerLine(prayerSnapshot),
      _exchangeLine(exchangeRateSnapshot),
    ];
    final eventsLine = _eventsLine(todayEvents);
    if (eventsLine != null) {
      lines.add(eventsLine);
    }

    return MorningBriefData(title: 'Aujourd\'hui à $cityName', lines: lines);
  }

  MorningBriefLine _weatherLine(WeatherSnapshot snapshot) {
    return switch (snapshot.state) {
      WeatherLoadState.success || WeatherLoadState.stale => MorningBriefLine(
        emoji: _weatherEmoji(snapshot.data!.weatherCode),
        text: '${snapshot.data!.temperature}°C',
      ),
      _ => const MorningBriefLine(emoji: '☁️', text: 'Météo indisponible'),
    };
  }

  MorningBriefLine _prayerLine(PrayerTimesSnapshot snapshot) {
    return switch (snapshot.state) {
      PrayerLoadState.success || PrayerLoadState.stale => MorningBriefLine(
        emoji: '🕌',
        text:
            '${snapshot.data!.nextPrayerName} ${snapshot.data!.nextPrayerCountdown}',
      ),
      _ => const MorningBriefLine(emoji: '🕌', text: 'Horaires indisponibles'),
    };
  }

  MorningBriefLine _exchangeLine(ExchangeRateSnapshot snapshot) {
    return switch (snapshot.state) {
      ExchangeRateLoadState.loading => const MorningBriefLine(
        emoji: '💶',
        text: 'Taux en cours…',
      ),
      ExchangeRateLoadState.success ||
      ExchangeRateLoadState.stale => MorningBriefLine(
        emoji: '💶',
        text:
            '1 ${snapshot.data!.fromCurrency} = ${snapshot.data!.rate.toStringAsFixed(2)} ${snapshot.data!.toCurrency}',
      ),
      _ => const MorningBriefLine(emoji: '💶', text: 'Taux indisponible'),
    };
  }

  /// Agenda — affiché uniquement s'il y a au moins une date listée (pas de filler).
  MorningBriefLine? _eventsLine(List<AtlasEvent> todayEvents) {
    if (todayEvents.isEmpty) return null;
    if (todayEvents.length == 1) {
      return MorningBriefLine(
        emoji: '📅',
        text: todayEvents.first.title,
        action: MorningBriefAction.events,
      );
    }
    return MorningBriefLine(
      emoji: '📅',
      text: '${todayEvents.length} dates utiles aujourd\'hui',
      action: MorningBriefAction.events,
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
