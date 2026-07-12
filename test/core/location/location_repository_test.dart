import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/location/location_constants.dart';
import 'package:atlas/core/location/location_repository.dart';
import 'package:atlas/core/location/reverse_geocoding_client.dart';
import 'package:atlas/core/location/geolocator_service.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('LocationRepository', () {
    test('renvoie Marrakech si la position est indisponible', () async {
      final repository = LocationRepository(
        geolocatorService: _NullGeolocatorService(),
      );

      final location = await repository.resolveLocation();

      expect(location.cityName, LocationConstants.fallbackCity);
      expect(location.latitude, LocationConstants.fallbackLatitude);
      expect(location.longitude, LocationConstants.fallbackLongitude);
      expect(location.isFromGps, isFalse);
    });

    test('renvoie la ville géocodée si le GPS est disponible', () async {
      final repository = LocationRepository(
        geolocatorService: _FixedGeolocatorService(
          latitude: 33.5731,
          longitude: -7.5898,
        ),
        reverseGeocodingClient: _FakeReverseGeocodingClient('Casablanca'),
      );

      final location = await repository.resolveLocation();

      expect(location.cityName, 'Casablanca');
      expect(location.latitude, 33.5731);
      expect(location.longitude, -7.5898);
      expect(location.isFromGps, isTrue);
    });

    test('conserve les coordonnées GPS si le géocodage échoue', () async {
      final repository = LocationRepository(
        geolocatorService: _FixedGeolocatorService(
          latitude: 34.0209,
          longitude: -6.8416,
        ),
        reverseGeocodingClient: _FailingReverseGeocodingClient(),
      );

      final location = await repository.resolveLocation();

      expect(location.cityName, LocationConstants.fallbackCity);
      expect(location.latitude, 34.0209);
      expect(location.longitude, -6.8416);
      expect(location.isFromGps, isTrue);
    });
  });
}

class _NullGeolocatorService extends GeolocatorService {
  @override
  Future<Position?> getCurrentPosition() async => null;
}

class _FixedGeolocatorService extends GeolocatorService {
  _FixedGeolocatorService({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  Future<Position?> getCurrentPosition() async {
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
  _FakeReverseGeocodingClient(this.cityName);

  final String cityName;

  @override
  Future<String> resolveCityName({
    required double latitude,
    required double longitude,
  }) async {
    return cityName;
  }
}

class _FailingReverseGeocodingClient extends ReverseGeocodingClient {
  @override
  Future<String> resolveCityName({
    required double latitude,
    required double longitude,
  }) async {
    throw Exception('geocoding error');
  }
}
