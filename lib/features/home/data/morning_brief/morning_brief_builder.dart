import 'package:flutter/material.dart';

import '../../../events/domain/models/atlas_event.dart';
import '../../domain/models/exchange_rate_snapshot.dart';
import '../../domain/models/prayer_times_snapshot.dart';
import '../../domain/models/weather_snapshot.dart';
import '../daily_insight/daily_insight_builder.dart';
import '../weather/weather_mapper.dart';

/// Identifiant d'action optionnel pour une ligne du briefing.
enum MorningBriefAction { weather, prayer, events }

/// Ligne scannable du briefing matinal.
class MorningBriefLine {
  const MorningBriefLine({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;

  /// Si non null, la ligne peut ouvrir une surface Atlas.
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
      title: titleFor(cityName),
      lines: const [],
      isLoading: true,
    );
  }

  /// Ville détectée / choisie ; jamais le fallback catalogue seul.
  static String titleFor(String cityName) {
    final city = cityName.trim();
    if (city.isEmpty) return 'Aujourd\'hui';
    return 'Aujourd\'hui à $city';
  }
}

/// Compose le briefing à partir des snapshots live — jamais de données inventées.
///
/// Intègre au plus une ligne contextuelle (chaleur / pluie / vendredi / agenda).
class MorningBriefBuilder {
  const MorningBriefBuilder({
    this.insightBuilder = const DailyInsightBuilder(),
  });

  final DailyInsightBuilder insightBuilder;

  MorningBriefData build({
    required String cityName,
    required WeatherSnapshot weatherSnapshot,
    required PrayerTimesSnapshot prayerSnapshot,
    required ExchangeRateSnapshot exchangeRateSnapshot,
    required List<AtlasEvent> todayEvents,
    DateTime? referenceTime,
  }) {
    final coreLoading = weatherSnapshot.state == WeatherLoadState.loading;

    if (coreLoading) {
      return MorningBriefData.loading(cityName: cityName);
    }

    final lines = <MorningBriefLine>[
      _weatherLine(weatherSnapshot),
      _prayerLine(prayerSnapshot),
      _exchangeLine(exchangeRateSnapshot),
    ];

    final insight = insightBuilder.build(
      weatherSnapshot: weatherSnapshot,
      cityName: cityName,
      todayEvents: todayEvents,
      referenceTime: referenceTime,
    );
    if (insight != null) {
      final isEventInsight = insight.message.startsWith('Aujourd\'hui —');
      lines.add(
        MorningBriefLine(
          icon: isEventInsight ? Icons.event_outlined : insight.icon,
          text: isEventInsight
              ? insight.message
                    .replaceFirst('Aujourd\'hui — ', '')
                    .replaceAll(RegExp(r'\.$'), '')
              : insight.message,
          action: isEventInsight ? MorningBriefAction.events : null,
        ),
      );
    }

    return MorningBriefData(
      title: MorningBriefData.titleFor(cityName),
      lines: lines,
    );
  }

  MorningBriefLine _weatherLine(WeatherSnapshot snapshot) {
    switch (snapshot.state) {
      case WeatherLoadState.success:
      case WeatherLoadState.stale:
        final data = snapshot.data!;
        final heat = data.temperature >= 34;
        final base = heat
            ? '${data.temperature}°C · chaleur'
            : '${data.temperature}°C';
        final text = snapshot.state == WeatherLoadState.stale
            ? '$base · météo enregistrée'
            : base;
        return MorningBriefLine(
          icon: WeatherMapper.iconForCode(data.weatherCode),
          text: text,
          action: MorningBriefAction.weather,
        );
      case WeatherLoadState.loading:
      case WeatherLoadState.unavailable:
        return const MorningBriefLine(
          icon: Icons.cloud_off_outlined,
          text: 'Météo indisponible',
        );
    }
  }

  MorningBriefLine _prayerLine(PrayerTimesSnapshot snapshot) {
    return switch (snapshot.state) {
      PrayerLoadState.success || PrayerLoadState.stale => MorningBriefLine(
        icon: Icons.mosque_outlined,
        text:
            '${snapshot.data!.nextPrayerName} ${snapshot.data!.nextPrayerCountdown}',
        action: MorningBriefAction.prayer,
      ),
      PrayerLoadState.loading => const MorningBriefLine(
        icon: Icons.mosque_outlined,
        text: 'Horaires en cours…',
      ),
      PrayerLoadState.needsLocation => const MorningBriefLine(
        icon: Icons.mosque_outlined,
        text: 'Localisation requise pour les horaires locaux',
      ),
      _ => const MorningBriefLine(
        icon: Icons.mosque_outlined,
        text: 'Horaires indisponibles',
      ),
    };
  }

  MorningBriefLine _exchangeLine(ExchangeRateSnapshot snapshot) {
    return switch (snapshot.state) {
      ExchangeRateLoadState.loading => const MorningBriefLine(
        icon: Icons.currency_exchange_outlined,
        text: 'Taux en cours…',
      ),
      ExchangeRateLoadState.success => MorningBriefLine(
        icon: Icons.currency_exchange_outlined,
        text:
            '1 ${snapshot.data!.fromCurrency} = ${snapshot.data!.rate.toStringAsFixed(2)} ${snapshot.data!.toCurrency}',
      ),
      ExchangeRateLoadState.stale => MorningBriefLine(
        icon: Icons.currency_exchange_outlined,
        text:
            '1 ${snapshot.data!.fromCurrency} = ${snapshot.data!.rate.toStringAsFixed(2)} ${snapshot.data!.toCurrency} · taux enregistré',
      ),
      _ => const MorningBriefLine(
        icon: Icons.currency_exchange_outlined,
        text: 'Taux indisponible',
      ),
    };
  }
}
