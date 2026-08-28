import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/datetime/atlas_display_clock.dart';
import 'package:atlas/core/location/atlas_city_source.dart';
import 'package:atlas/core/location/atlas_geo_country.dart';
import 'package:atlas/core/location/location_constants.dart';
import 'package:atlas/core/location/morocco_cities.dart';
import 'package:atlas/core/location/user_location.dart';
import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/home/data/morning_brief/morning_brief_builder.dart';
import 'package:atlas/features/home/data/prayer/prayer_calculation_policy.dart';
import 'package:atlas/features/home/domain/models/exchange_rate_snapshot.dart';
import 'package:atlas/features/home/domain/models/prayer_times_snapshot.dart';
import 'package:atlas/features/home/domain/models/weather_snapshot.dart';
import 'package:atlas/features/home/presentation/widgets/prayer_time_card.dart';

void main() {
  group('AtlasGeoCountry', () {
    test('Paris → FR, Marrakech → MA', () {
      expect(
        AtlasGeoCountry.guessIsoCode(latitude: 48.8566, longitude: 2.3522),
        'FR',
      );
      expect(
        AtlasGeoCountry.guessIsoCode(
          latitude: LocationConstants.fallbackLatitude,
          longitude: LocationConstants.fallbackLongitude,
        ),
        'MA',
      );
    });
  });

  group('PrayerCalculationPolicy', () {
    test('GPS France réussi : coords France + fuseau Paris + UOIF', () {
      const location = UserLocation(
        latitude: 48.8566,
        longitude: 2.3522,
        cityName: 'Paris',
        countryCode: 'FR',
        isFromGps: true,
      );

      final plan = PrayerCalculationPolicy.resolve(
        citySource: AtlasCitySource.auto,
        location: location,
      );

      expect(plan.canFetch, isTrue);
      expect(plan.latitude, 48.8566);
      expect(plan.longitude, 2.3522);
      expect(plan.countryCode, 'FR');
      expect(plan.methodId, PrayerCalculationPolicy.franceUoifMethodId);
      expect(plan.timeZoneString, 'Europe/Paris');
      expect(plan.methodLabel, PrayerCalculationPolicy.franceUoifLabel);
      expect(plan.methodId, isNot(PrayerCalculationPolicy.moroccoMethodId));
    });

    test('GPS Maroc réussi : coords Maroc + méthode Maroc', () {
      final location = UserLocation(
        latitude: MoroccoCities.casablanca.latitude,
        longitude: MoroccoCities.casablanca.longitude,
        cityName: 'Casablanca',
        countryCode: 'MA',
        isFromGps: true,
      );

      final plan = PrayerCalculationPolicy.resolve(
        citySource: AtlasCitySource.auto,
        location: location,
      );

      expect(plan.canFetch, isTrue);
      expect(plan.latitude, MoroccoCities.casablanca.latitude);
      expect(plan.longitude, MoroccoCities.casablanca.longitude);
      expect(plan.methodId, PrayerCalculationPolicy.moroccoMethodId);
      expect(plan.timeZoneString, AtlasDisplayClock.casablancaTimeZone);
      expect(plan.methodLabel, PrayerCalculationPolicy.moroccoLabel);
    });

    test(
      'GPS refusé en auto : aucun horaire Marrakech comme horaire local',
      () {
        const location = UserLocation.catalogFallback;
        expect(location.latitude, LocationConstants.fallbackLatitude);

        final plan = PrayerCalculationPolicy.resolve(
          citySource: AtlasCitySource.auto,
          location: location,
        );

        expect(location.isResolved, isFalse);
        expect(plan.canFetch, isFalse);
        expect(plan.latitude, isNull);
        expect(plan.longitude, isNull);
        expect(plan.method, isNull);
      },
    );

    test('timeout GPS en auto : même blocage, pas de coords Marrakech', () {
      const location = UserLocation.catalogFallback;

      final plan = PrayerCalculationPolicy.resolve(
        citySource: AtlasCitySource.auto,
        location: location,
      );

      expect(plan.canFetch, isFalse);
      expect(plan.latitude, isNull);
      expect(plan.latitude, isNot(LocationConstants.fallbackLatitude));
    });

    test('Marrakech choisie manuellement : coords + méthode Maroc', () {
      final location = UserLocation(
        latitude: MoroccoCities.marrakech.latitude,
        longitude: MoroccoCities.marrakech.longitude,
        cityName: 'Marrakech',
        contentCityName: 'Marrakech',
        countryCode: 'MA',
        isFromGps: false,
      );

      final plan = PrayerCalculationPolicy.resolve(
        citySource: AtlasCitySource.manual,
        location: location,
      );

      expect(plan.canFetch, isTrue);
      expect(plan.latitude, MoroccoCities.marrakech.latitude);
      expect(plan.longitude, MoroccoCities.marrakech.longitude);
      expect(plan.methodId, PrayerCalculationPolicy.moroccoMethodId);
      expect(plan.timeZoneString, AtlasDisplayClock.casablancaTimeZone);
    });

    test('choix manuel Fès non écrasé par un GPS France', () {
      final fes = UserLocation(
        latitude: MoroccoCities.fes.latitude,
        longitude: MoroccoCities.fes.longitude,
        cityName: 'Fès',
        contentCityName: 'Fès',
        countryCode: 'MA',
        isFromGps: false,
      );

      final plan = PrayerCalculationPolicy.resolve(
        citySource: AtlasCitySource.manual,
        location: fes,
      );

      expect(plan.latitude, MoroccoCities.fes.latitude);
      expect(plan.longitude, MoroccoCities.fes.longitude);
      expect(plan.methodId, PrayerCalculationPolicy.moroccoMethodId);
      expect(plan.countryCode, 'MA');
      expect(plan.latitude, isNot(48.8566));
    });
  });

  group('Accueil — état honnête', () {
    test('briefing auto sans GPS : pas d\'horaires Marrakech', () {
      const builder = MorningBriefBuilder();
      final data = builder.build(
        cityName: '',
        weatherSnapshot: const WeatherSnapshot.unavailable(),
        prayerSnapshot: const PrayerTimesSnapshot.needsLocation(),
        exchangeRateSnapshot: const ExchangeRateSnapshot.unavailable(),
        todayEvents: const [],
      );

      expect(
        data.lines.any((l) => l.text.contains('Localisation requise')),
        isTrue,
      );
      expect(data.lines.any((l) => l.text.contains('Fajr')), isFalse);
      expect(data.lines.any((l) => l.text.contains('05:')), isFalse);
      expect(data.title, isNot(contains('Marrakech')));
    });

    testWidgets('carte prière : localisation requise sans horaires', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AtlasTheme.light,
          home: const Scaffold(
            body: PrayerTimeCard(snapshot: PrayerTimesSnapshot.needsLocation()),
          ),
        ),
      );

      expect(find.text('Localisation requise'), findsOneWidget);
      expect(find.textContaining('Autorisez la localisation'), findsOneWidget);
      expect(find.text('Fajr'), findsNothing);
      expect(find.textContaining('Marrakech'), findsNothing);
    });
  });
}
