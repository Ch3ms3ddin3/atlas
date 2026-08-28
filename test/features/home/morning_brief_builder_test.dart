import 'package:atlas/features/home/data/morning_brief/morning_brief_builder.dart';
import 'package:atlas/features/home/domain/models/exchange_rate_snapshot.dart';
import 'package:atlas/features/home/domain/models/home_models.dart';
import 'package:atlas/features/home/domain/models/prayer_times_snapshot.dart';
import 'package:atlas/features/home/domain/models/weather_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = MorningBriefBuilder();

  // Mercredi midi — hors vendredi / hors soirée clémente.
  final wednesdayNoon = DateTime(2026, 8, 12, 12);

  WeatherSnapshot weather({
    int temp = 28,
    WeatherLoadState state = WeatherLoadState.success,
  }) {
    return WeatherSnapshot(
      state: state,
      data: state == WeatherLoadState.unavailable
          ? null
          : WeatherData(
              temperature: temp,
              feelsLike: temp,
              condition: 'Ciel dégagé',
              icon: Icons.wb_sunny_outlined,
              weatherCode: 0,
              fetchedAt: wednesdayNoon,
            ),
    );
  }

  PrayerTimesSnapshot prayer({
    PrayerLoadState state = PrayerLoadState.success,
  }) {
    return PrayerTimesSnapshot(
      state: state,
      data:
          state == PrayerLoadState.unavailable ||
              state == PrayerLoadState.needsLocation
          ? null
          : const PrayerTimeData(
              nextPrayerName: 'Asr',
              nextPrayerCountdown: 'dans 40 min',
              schedule: [
                PrayerScheduleItem(
                  name: 'Asr',
                  time: '16:42',
                  isCurrent: false,
                  isNext: true,
                ),
              ],
              calculationMethod: 'Maroc',
            ),
    );
  }

  ExchangeRateSnapshot fx({
    ExchangeRateLoadState state = ExchangeRateLoadState.success,
  }) {
    return ExchangeRateSnapshot(
      state: state,
      data: state == ExchangeRateLoadState.unavailable
          ? null
          : ExchangeRateData(
              fromCurrency: 'EUR',
              toCurrency: 'MAD',
              rate: 10.72,
              sourceLabel: 'Frankfurter',
              referenceDate: '2026-08-12',
              fetchedAt: wednesdayNoon,
            ),
    );
  }

  test('loading tant que météo ou prière chargent', () {
    final data = builder.build(
      cityName: 'Marrakech',
      weatherSnapshot: const WeatherSnapshot.loading(),
      prayerSnapshot: prayer(),
      exchangeRateSnapshot: fx(),
      todayEvents: const [],
      referenceTime: wednesdayNoon,
    );
    expect(data.isLoading, isTrue);
  });

  test('lignes météo / prière / FX + chaleur', () {
    final data = builder.build(
      cityName: 'Marrakech',
      weatherSnapshot: weather(temp: 38),
      prayerSnapshot: prayer(),
      exchangeRateSnapshot: fx(),
      todayEvents: const [],
      referenceTime: wednesdayNoon,
    );
    expect(data.isLoading, isFalse);
    expect(data.lines.length, greaterThanOrEqualTo(3));
    expect(data.lines[0].text, contains('38°C'));
    expect(data.lines[0].text, contains('chaleur'));
    expect(data.lines[0].action, MorningBriefAction.weather);
    expect(data.lines[1].action, MorningBriefAction.prayer);
    expect(data.lines[2].text, contains('10.72'));
    expect(data.lines.any((l) => l.text.contains('Chaleur intense')), isTrue);
  });

  test('FX stale affiche taux enregistré', () {
    final data = builder.build(
      cityName: 'Marrakech',
      weatherSnapshot: weather(),
      prayerSnapshot: prayer(),
      exchangeRateSnapshot: fx(state: ExchangeRateLoadState.stale),
      todayEvents: const [],
      referenceTime: wednesdayNoon,
    );
    expect(data.lines[2].text, contains('taux enregistré'));
  });

  test('indisponibilités honnêtes', () {
    final data = builder.build(
      cityName: 'Marrakech',
      weatherSnapshot: weather(state: WeatherLoadState.unavailable),
      prayerSnapshot: prayer(state: PrayerLoadState.unavailable),
      exchangeRateSnapshot: fx(state: ExchangeRateLoadState.unavailable),
      todayEvents: const [],
      referenceTime: wednesdayNoon,
    );
    expect(data.lines[0].text, 'Météo indisponible');
    expect(data.lines[1].text, 'Horaires indisponibles');
    expect(data.lines[2].text, 'Taux indisponible');
  });
}
