import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/location/atlas_city_source.dart';
import 'package:atlas/core/location/location_constants.dart';
import 'package:atlas/core/location/location_repository.dart';
import 'package:atlas/core/location/morocco_cities.dart';
import 'package:atlas/core/location/reverse_geocoding_client.dart';
import 'package:atlas/core/location/geolocator_service.dart';
import 'package:atlas/core/location/user_location.dart';
import 'package:atlas/features/profile/domain/models/user_profile.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('LocationRepository', () {
    test(
      'premier lancement auto : GPS absent ≠ Marrakech comme localisation',
      () async {
        final repository = LocationRepository(
          geolocatorService: _NullGeolocatorService(),
        );

        final location = await repository.resolveLocation();

        expect(location.cityName, isEmpty);
        expect(location.displayCityName, isEmpty);
        expect(location.catalogCity, LocationConstants.fallbackCity);
        expect(location.isResolved, isFalse);
        expect(location.isFromGps, isFalse);
        expect(location.latitude, LocationConstants.fallbackLatitude);
        expect(location.longitude, LocationConstants.fallbackLongitude);
      },
    );

    test('Marrakech par défaut n\'est pas un choix manuel', () async {
      final location = await LocationRepository(
        geolocatorService: _NullGeolocatorService(),
      ).resolveForProfile(UserProfile.defaults);

      expect(UserProfile.defaults.citySource, AtlasCitySource.auto);
      expect(location.cityName, isEmpty);
      expect(location.catalogCity, 'Marrakech');
      expect(location.isFromGps, isFalse);
    });

    test('auto ignore preferredCity Marrakech et utilise le GPS', () async {
      final repository = LocationRepository(
        geolocatorService: _FixedGeolocatorService(
          latitude: 33.5731,
          longitude: -7.5898,
        ),
        reverseGeocodingClient: _FakeReverseGeocodingClient(
          'Casablanca',
          countryCode: 'MA',
        ),
      );

      final location = await repository.resolveLocation(
        preferredCityName: 'Marrakech',
        citySource: AtlasCitySource.auto,
      );

      expect(location.cityName, 'Casablanca');
      expect(location.catalogCity, 'Casablanca');
      expect(location.latitude, 33.5731);
      expect(location.isFromGps, isTrue);
      expect(location.countryCode, 'MA');
    });

    test('manual : ville préférée si le GPS est indisponible', () async {
      final repository = LocationRepository(
        geolocatorService: _NullGeolocatorService(),
      );

      final location = await repository.resolveLocation(
        preferredCityName: 'Casablanca',
        citySource: AtlasCitySource.manual,
      );

      expect(location.cityName, 'Casablanca');
      expect(location.catalogCity, 'Casablanca');
      expect(location.latitude, MoroccoCities.casablanca.latitude);
      expect(location.longitude, MoroccoCities.casablanca.longitude);
      expect(location.isFromGps, isFalse);
    });

    test('manual Fès prime sur le GPS (pas de rewrite silencieux)', () async {
      final repository = LocationRepository(
        geolocatorService: _FixedGeolocatorService(
          latitude: 31.6295,
          longitude: -7.9811,
        ),
        reverseGeocodingClient: _FakeReverseGeocodingClient('Marrakech'),
      );

      final location = await repository.resolveLocation(
        preferredCityName: 'Fès',
        citySource: AtlasCitySource.manual,
      );

      expect(location.cityName, 'Fès');
      expect(location.catalogCity, 'Fès');
      expect(location.latitude, MoroccoCities.fes.latitude);
      expect(location.longitude, MoroccoCities.fes.longitude);
      expect(location.isFromGps, isFalse);
    });

    test('auto : ville géocodée si le GPS est disponible', () async {
      final repository = LocationRepository(
        geolocatorService: _FixedGeolocatorService(
          latitude: 33.5731,
          longitude: -7.5898,
        ),
        reverseGeocodingClient: _FakeReverseGeocodingClient(
          'Casablanca',
          countryCode: 'MA',
        ),
      );

      final location = await repository.resolveLocation();

      expect(location.cityName, 'Casablanca');
      expect(location.catalogCity, 'Casablanca');
      expect(location.latitude, 33.5731);
      expect(location.longitude, -7.5898);
      expect(location.isFromGps, isTrue);
    });

    test(
      'auto : conserve les coordonnées GPS si le géocodage échoue',
      () async {
        final repository = LocationRepository(
          geolocatorService: _FixedGeolocatorService(
            latitude: 34.0209,
            longitude: -6.8416,
          ),
          reverseGeocodingClient: _FailingReverseGeocodingClient(),
        );

        final location = await repository.resolveLocation();

        expect(location.cityName, isEmpty);
        expect(location.catalogCity, LocationConstants.fallbackCity);
        expect(location.latitude, 34.0209);
        expect(location.longitude, -6.8416);
        expect(location.isFromGps, isTrue);
        expect(location.isResolved, isTrue);
      },
    );

    test(
      'permission refusée : fallback catalogue sans prétendre Marrakech',
      () async {
        final repository = LocationRepository(
          geolocatorService: _NullGeolocatorService(),
        );

        final location = await repository.resolveForProfile(
          UserProfile.defaults,
        );

        expect(location, sameAsUnresolvedFallback);
      },
    );

    test(
      'timeout GPS : même repli catalogue, pas une position réelle',
      () async {
        final repository = LocationRepository(
          geolocatorService: _TimeoutGeolocatorService(),
        );

        final location = await repository.resolveLocation(
          citySource: AtlasCitySource.auto,
        );

        expect(location, sameAsUnresolvedFallback);
        expect(location.countryCode, isEmpty);
      },
    );

    test(
      'GPS hors zone couverte : catalogue Marrakech, ville détectée réelle',
      () async {
        final repository = LocationRepository(
          geolocatorService: _FixedGeolocatorService(
            latitude: 48.8566,
            longitude: 2.3522,
          ),
          reverseGeocodingClient: _FakeReverseGeocodingClient(
            'Paris',
            countryCode: 'FR',
          ),
        );

        final location = await repository.resolveLocation();

        expect(location.cityName, 'Paris');
        expect(location.displayCityName, 'Paris');
        expect(location.catalogCity, LocationConstants.fallbackCity);
        expect(location.usesCatalogFallback, isTrue);
        expect(location.isFromGps, isTrue);
        expect(location.countryCode, 'FR');
        expect(location.latitude, 48.8566);
        expect(location.longitude, 2.3522);
      },
    );

    test('resolveForProfile manuel conserve Fès', () async {
      const profile = UserProfile(
        firstName: 'Salma',
        preferredCity: 'Fès',
        language: AtlasLanguage.french,
        userType: AtlasUserType.resident,
        citySource: AtlasCitySource.manual,
      );

      final location = await LocationRepository(
        geolocatorService: _FixedGeolocatorService(
          latitude: 48.8566,
          longitude: 2.3522,
        ),
        reverseGeocodingClient: _FakeReverseGeocodingClient(
          'Paris',
          countryCode: 'FR',
        ),
      ).resolveForProfile(profile);

      expect(location.cityName, 'Fès');
      expect(location.isFromGps, isFalse);
      expect(location.countryCode, 'MA');
    });
  });

  group('UserLocation', () {
    test('catalogFallback ne présente pas Marrakech comme localisation', () {
      const location = UserLocation.catalogFallback;
      expect(location.displayCityName, isEmpty);
      expect(location.catalogCity, 'Marrakech');
      expect(location.isResolved, isFalse);
    });
  });
}

Matcher get sameAsUnresolvedFallback => predicate<UserLocation>((location) {
  return location.cityName.isEmpty &&
      location.catalogCity == LocationConstants.fallbackCity &&
      location.isFromGps == false &&
      location.isResolved == false;
});

class _TimeoutGeolocatorService extends GeolocatorService {
  @override
  Future<Position?> getCurrentPosition({bool userInitiated = false}) async {
    throw TimeoutException('gps timeout');
  }
}

class _NullGeolocatorService extends GeolocatorService {
  @override
  Future<Position?> getCurrentPosition({bool userInitiated = false}) async =>
      null;
}

class _FixedGeolocatorService extends GeolocatorService {
  _FixedGeolocatorService({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  Future<Position?> getCurrentPosition({bool userInitiated = false}) async {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.utc(2026, 7, 12),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

class _FakeReverseGeocodingClient extends ReverseGeocodingClient {
  _FakeReverseGeocodingClient(this.cityName, {this.countryCode});

  final String cityName;
  final String? countryCode;

  @override
  Future<ReverseGeocodePlace> resolvePlace({
    required double latitude,
    required double longitude,
  }) async {
    return ReverseGeocodePlace(cityName: cityName, countryCode: countryCode);
  }
}

class _FailingReverseGeocodingClient extends ReverseGeocodingClient {
  @override
  Future<ReverseGeocodePlace> resolvePlace({
    required double latitude,
    required double longitude,
  }) async {
    throw Exception('geocoding error');
  }
}
