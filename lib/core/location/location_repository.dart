import 'location_constants.dart';
import 'geolocator_service.dart';
import 'reverse_geocoding_client.dart';
import 'user_location.dart';

/// Orchestre la résolution de la position utilisateur avec repli Marrakech.
class LocationRepository {
  LocationRepository({
    GeolocatorService? geolocatorService,
    ReverseGeocodingClient? reverseGeocodingClient,
  })  : _geolocatorService = geolocatorService ?? const GeolocatorService(),
        _reverseGeocodingClient =
            reverseGeocodingClient ?? const ReverseGeocodingClient();

  final GeolocatorService _geolocatorService;
  final ReverseGeocodingClient _reverseGeocodingClient;

  /// Tente GPS + reverse geocoding ; renvoie Marrakech en cas d'échec.
  Future<UserLocation> resolveLocation() async {
    final position = await _geolocatorService.getCurrentPosition();
    if (position == null) {
      return _fallbackLocation();
    }

    try {
      final cityName = await _reverseGeocodingClient.resolveCityName(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        cityName: cityName,
        isFromGps: true,
      );
    } catch (_) {
      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        cityName: LocationConstants.fallbackCity,
        isFromGps: true,
      );
    }
  }

  UserLocation _fallbackLocation() {
    return const UserLocation(
      latitude: LocationConstants.fallbackLatitude,
      longitude: LocationConstants.fallbackLongitude,
      cityName: LocationConstants.fallbackCity,
      isFromGps: false,
    );
  }
}
