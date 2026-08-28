import 'package:geolocator/geolocator.dart';

import '../../features/profile/domain/models/user_profile.dart';
import 'atlas_city_source.dart';
import 'atlas_geo_country.dart';
import 'location_constants.dart';
import 'geolocator_service.dart';
import 'morocco_cities.dart';
import 'reverse_geocoding_client.dart';
import 'user_location.dart';

/// Orchestre la résolution de la position.
///
/// **Manuel** : la ville du profil est autoritative (le GPS n'écrase jamais).
/// **Auto** : GPS + reverse geocode ; hors zone → catalogue Marrakech sans
/// prétendre que l'utilisateur y est.
class LocationRepository {
  LocationRepository({
    GeolocatorService? geolocatorService,
    ReverseGeocodingClient? reverseGeocodingClient,
  }) : _geolocatorService = geolocatorService ?? const GeolocatorService(),
       _reverseGeocodingClient =
           reverseGeocodingClient ?? const ReverseGeocodingClient();

  final GeolocatorService _geolocatorService;
  final ReverseGeocodingClient _reverseGeocodingClient;

  /// Point d'entrée unique Accueil / Explorer / Carte / Prix.
  Future<UserLocation> resolveForProfile(UserProfile profile) {
    return resolveLocation(
      preferredCityName: profile.preferredCity,
      citySource: profile.citySource,
    );
  }

  /// Résout la position Atlas.
  Future<UserLocation> resolveLocation({
    String? preferredCityName,
    AtlasCitySource citySource = AtlasCitySource.auto,
  }) async {
    if (citySource == AtlasCitySource.manual) {
      return _manualLocation(preferredCityName);
    }
    return _autoLocation();
  }

  UserLocation _manualLocation(String? preferredCityName) {
    final city =
        MoroccoCities.resolve(preferredCityName) ?? MoroccoCities.fallback;
    return UserLocation(
      latitude: city.latitude,
      longitude: city.longitude,
      cityName: city.name,
      contentCityName: city.name,
      countryCode: 'MA',
      isFromGps: false,
    );
  }

  Future<UserLocation> _autoLocation() async {
    final position = await _readGps();
    if (position == null) {
      return UserLocation.catalogFallback;
    }

    ReverseGeocodePlace? place;
    try {
      place = await _reverseGeocodingClient.resolvePlace(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      place = null;
    }

    final detectedName = place?.cityName ?? '';
    final countryCode =
        place?.countryCode?.trim().toUpperCase() ??
        AtlasGeoCountry.guessIsoCode(
          latitude: position.latitude,
          longitude: position.longitude,
        ) ??
        '';

    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      cityName: detectedName,
      contentCityName: contentCityFor(detectedName),
      countryCode: countryCode,
      isFromGps: true,
    );
  }

  Future<Position?> _readGps() async {
    try {
      return await _geolocatorService.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  /// Ville catalogue : ville Maroc connue, sinon repli Marrakech (pas de Paris).
  static String contentCityFor(String? detectedOrManual) {
    return MoroccoCities.resolve(detectedOrManual)?.name ??
        LocationConstants.fallbackCity;
  }
}
