import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/events/domain/models/atlas_event.dart';
import 'package:atlas/features/home/data/daily_insight/daily_insight_builder.dart';
import 'package:atlas/features/home/data/morning_brief/morning_brief_builder.dart';
import 'package:atlas/features/home/data/pour_vous/pour_vous_builder.dart';
import 'package:atlas/features/home/domain/models/exchange_rate_snapshot.dart';
import 'package:atlas/features/home/domain/models/home_models.dart';
import 'package:atlas/features/home/domain/models/prayer_times_snapshot.dart';
import 'package:atlas/features/home/domain/models/weather_snapshot.dart';
import 'package:flutter/material.dart';

void main() {
  group('MorningBriefBuilder', () {
    const builder = MorningBriefBuilder();

    test('loading when any live snapshot is loading', () {
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

    test('compose five briefing lines without inventing live values', () {
      final data = builder.build(
        cityName: 'Casablanca',
        weatherSnapshot: const WeatherSnapshot.unavailable(),
        prayerSnapshot: const PrayerTimesSnapshot.unavailable(),
        exchangeRateSnapshot: const ExchangeRateSnapshot.unavailable(),
        todayEvents: const [],
      );

      expect(data.isLoading, isFalse);
      expect(data.lines, hasLength(5));
      expect(data.lines[0].text, 'Météo indisponible');
      expect(data.lines[1].text, 'Horaires indisponibles');
      expect(data.lines[2].text, 'Taux indisponible');
      expect(data.lines[3].emoji, '🚦');
      expect(data.lines[4].text, 'Agenda · aucun férié listé aujourd\'hui');
      expect(data.lines[4].action, MorningBriefAction.events);
    });

    test('shows live weather temperature when available', () {
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
    });
  });

  group('PourVousBuilder', () {
    const builder = PourVousBuilder();

    test('returns at most two recommendations', () {
      final items = builder.build(
        weatherSnapshot: WeatherSnapshot(
          state: WeatherLoadState.success,
          data: WeatherData(
            temperature: 36,
            feelsLike: 38,
            condition: 'Ciel dégagé',
            icon: Icons.wb_sunny_outlined,
            weatherCode: 0,
          ),
        ),
        cityName: 'Marrakech',
      );

      expect(items.length, lessThanOrEqualTo(2));
      expect(items, isNotEmpty);
    });

    test('includes Majorelle tip for Marrakech when slots remain', () {
      final items = builder.build(
        weatherSnapshot: const WeatherSnapshot.unavailable(),
        cityName: 'Marrakech',
      );

      expect(items.any((item) => item.message.contains('Majorelle')), isTrue);
      expect(items.first.icon, isNotNull);
      expect(items.first.title, isNotEmpty);
    });
  });

  group('DailyInsightBuilder', () {
    const builder = DailyInsightBuilder();

    test('always returns one insight', () {
      final insight = builder.build(
        weatherSnapshot: const WeatherSnapshot.unavailable(),
        cityName: 'Fès',
      );

      expect(insight.message, isNotEmpty);
    });

    test('warns on intense heat when weather is available', () {
      final insight = builder.build(
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

      expect(insight.message.toLowerCase(), contains('chaleur'));
    });
  });
}
