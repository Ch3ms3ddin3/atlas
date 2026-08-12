import 'location_constants.dart';
import 'geolocator_service.dart';
import 'morocco_cities.dart';
import 'reverse_geocoding_client.dart';
import 'user_location.dart';

/// Orchestre la résolution de la position.
///
/// Ordre : **ville préférée explicite** → GPS + reverse geocode → Marrakech.
/// Une ville de profil ne doit jamais être écrasée silencieusement par le GPS
/// (ex. Fès → Marrakech après quelques secondes).
class LocationRepository {
  LocationRepository({
    GeolocatorService? geolocatorService,
    ReverseGeocodingClient? reverseGeocodingClient,
  }) : _geolocatorService = geolocatorService ?? const GeolocatorService(),
       _reverseGeocodingClient =
           reverseGeocodingClient ?? const ReverseGeocodingClient();

  final GeolocatorService _geolocatorService;
  final ReverseGeocodingClient _reverseGeocodingClient;

  /// Résout la position Atlas.
  ///
  /// Quand [preferredCityName] correspond à une ville MoroccoCities connue,
  /// elle est autoritative (coordonnées catalogue). Le GPS n'est utilisé que
  /// sans préférence explicite.
  Future<UserLocation> resolveLocation({String? preferredCityName}) async {
    final preferred = MoroccoCities.resolve(preferredCityName);
    if (preferred != null) {
      return UserLocation(
        latitude: preferred.latitude,
        longitude: preferred.longitude,
        cityName: preferred.name,
        isFromGps: false,
      );
    }

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
    final city =
        MoroccoCities.resolve(preferredCityName) ?? MoroccoCities.fallback;
    return UserLocation(
      latitude: city.latitude,
      longitude: city.longitude,
      cityName: city.name,
      isFromGps: false,
    );
  }
}
