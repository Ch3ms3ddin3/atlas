import 'location_constants.dart';
import 'geolocator_service.dart';
import 'morocco_cities.dart';
import 'reverse_geocoding_client.dart';
import 'user_location.dart';

/// Orchestre la résolution de la position : GPS → ville préférée → Marrakech.
class LocationRepository {
  LocationRepository({
    GeolocatorService? geolocatorService,
    ReverseGeocodingClient? reverseGeocodingClient,
  })  : _geolocatorService = geolocatorService ?? const GeolocatorService(),
        _reverseGeocodingClient =
            reverseGeocodingClient ?? const ReverseGeocodingClient();

  final GeolocatorService _geolocatorService;
  final ReverseGeocodingClient _reverseGeocodingClient;

  /// Tente GPS + reverse geocoding ; repli sur [preferredCityName] puis Marrakech.
  Future<UserLocation> resolveLocation({String? preferredCityName}) async {
    final position = await _geolocatorService.getCurrentPosition();
    if (position == null) {
      return _preferredOrFallbackLocation(preferredCityName);
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

  UserLocation _preferredOrFallbackLocation(String? preferredCityName) {
    final city = MoroccoCities.resolve(preferredCityName) ?? MoroccoCities.fallback;
    return UserLocation(
      latitude: city.latitude,
      longitude: city.longitude,
      cityName: city.name,
      isFromGps: false,
    );
  }
}
