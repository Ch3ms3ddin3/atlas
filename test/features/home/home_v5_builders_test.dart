import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/events/domain/models/atlas_event.dart';
import 'package:atlas/features/home/data/daily_insight/daily_insight_builder.dart';
import 'package:atlas/features/home/data/morning_brief/morning_brief_builder.dart';
import 'package:atlas/features/home/domain/models/exchange_rate_snapshot.dart';
import 'package:atlas/features/home/domain/models/home_models.dart';
import 'package:atlas/features/home/domain/models/prayer_times_snapshot.dart';
import 'package:atlas/features/home/domain/models/weather_snapshot.dart';

void main() {
  group('MorningBriefBuilder', () {
    const builder = MorningBriefBuilder();

    test('loading when weather or prayer is still loading', () {
      final data = builder.build(
        cityName: 'Marrakech',
        weatherSnapshot: const WeatherSnapshot.loading(),
        prayerSnapshot: const PrayerTimesSnapshot.unavailable(),
        exchangeRateSnapshot: const ExchangeRateSnapshot.unavailable(),
        todayEvents: const [],
      );

      expect(data.isLoading, isTrue);
      expect(data.title, 'Aujourd\'hui à Marrakech');
      expect(data.lines, isEmpty);
    });

    test('does not invent traffic and omits empty agenda line', () {
      final data = builder.build(
        cityName: 'Casablanca',
        weatherSnapshot: const WeatherSnapshot.unavailable(),
        prayerSnapshot: const PrayerTimesSnapshot.unavailable(),
        exchangeRateSnapshot: const ExchangeRateSnapshot.unavailable(),
        todayEvents: const [],
      );

      expect(data.isLoading, isFalse);
      expect(data.lines, hasLength(3));
      expect(data.lines[0].text, 'Météo indisponible');
      expect(data.lines[1].text, 'Horaires indisponibles');
      expect(data.lines[2].text, 'Taux indisponible');
      expect(data.lines.any((l) => l.emoji == '🚦'), isFalse);
      expect(data.lines.any((l) => l.text.contains('Circulation')), isFalse);
      expect(data.lines.any((l) => l.text.contains('férié')), isFalse);
      expect(data.lines.any((l) => l.emoji == '📅'), isFalse);
    });

    test('shows FX loading without blocking the brief', () {
      final data = builder.build(
        cityName: 'Rabat',
        weatherSnapshot: const WeatherSnapshot.unavailable(),
        prayerSnapshot: const PrayerTimesSnapshot.unavailable(),
        exchangeRateSnapshot: const ExchangeRateSnapshot.loading(),
        todayEvents: const [],
      );

      expect(data.isLoading, isFalse);
      expect(data.lines[2].text, 'Taux en cours…');
    });

    test('shows live weather and agenda only when events exist', () {
      final data = builder.build(
        cityName: 'Rabat',
        weatherSnapshot: WeatherSnapshot(
          state: WeatherLoadState.success,
          data: WeatherData(
            temperature: 24,
            feelsLike: 23,
            condition: 'Peu nuageux',
            icon: Icons.wb_cloudy_outlined,
            weatherCode: 1,
          ),
        ),
        prayerSnapshot: const PrayerTimesSnapshot.unavailable(),
        exchangeRateSnapshot: const ExchangeRateSnapshot.unavailable(),
        todayEvents: [
          AtlasEvent(
            id: 'e1',
            title: 'Festival test',
            description: 'Description',
            category: EventCategory.culturalFestival,
            startAt: DateTime(2026, 8, 7),
            isAllDay: true,
            source: 'test',
            reliability: EventReliability.confirmed,
            cityName: 'Rabat',
          ),
        ],
      );

      expect(data.lines.first.text, '24°C');
      expect(data.lines.last.text, 'Festival test');
      expect(data.lines.last.action, MorningBriefAction.events);
    });
  });

  group('DailyInsightBuilder', () {
    const builder = DailyInsightBuilder();

    test('returns null without weather, friday, or events', () {
      // Force a non-Friday reference by checking: builder uses casablancaNow().
      // When weather unavailable and no events, tip must be null unless Friday.
      final tip = builder.build(
        weatherSnapshot: const WeatherSnapshot.unavailable(),
        cityName: 'Fès',
        todayEvents: const [],
      );

      final isFriday =
          DateTime.now().toUtc().add(const Duration(hours: 1)).weekday ==
          DateTime.friday;
      if (isFriday) {
        expect(tip, isNotNull);
        expect(tip!.message.toLowerCase(), contains('vendredi'));
      } else {
        expect(tip, isNull);
      }
    });

    test('warns on intense heat when weather is available', () {
      final tip = builder.build(
        weatherSnapshot: WeatherSnapshot(
          state: WeatherLoadState.success,
          data: WeatherData(
            temperature: 36,
            feelsLike: 40,
            condition: 'Ciel dégagé',
            icon: Icons.wb_sunny_outlined,
            weatherCode: 0,
          ),
        ),
        cityName: 'Marrakech',
      );

      expect(tip, isNotNull);
      expect(tip!.message.toLowerCase(), contains('chaleur'));
    });

    test('surfaces today events as a tip when no weather signal', () {
      final tip = builder.build(
        weatherSnapshot: const WeatherSnapshot.unavailable(),
        cityName: 'Rabat',
        todayEvents: [
          AtlasEvent(
            id: 'e1',
            title: 'Fête du Trône',
            description: 'Férié national',
            category: EventCategory.publicHoliday,
            startAt: DateTime(2026, 7, 30),
            isAllDay: true,
            source: 'test',
            reliability: EventReliability.confirmed,
            cityName: 'Rabat',
          ),
        ],
      );

      // Heat/friday may take precedence depending on clock; with unavailable
      // weather, friday tip wins on Friday, else event tip.
      expect(tip, isNotNull);
      final isFriday =
          DateTime.now().toUtc().add(const Duration(hours: 1)).weekday ==
          DateTime.friday;
      if (isFriday) {
        expect(tip!.message.toLowerCase(), contains('vendredi'));
      } else {
        expect(tip!.message, contains('Fête du Trône'));
      }
    });

    test('does not invent Majorelle or identity filler tips', () {
      final tip = builder.build(
        weatherSnapshot: const WeatherSnapshot.unavailable(),
        cityName: 'Marrakech',
        todayEvents: const [],
      );

      if (tip != null) {
        expect(tip.message.contains('Majorelle'), isFalse);
        expect(tip.message.toLowerCase().contains('identité'), isFalse);
        expect(tip.message.toLowerCase().contains('passeport'), isFalse);
      }
    });
  });
}
