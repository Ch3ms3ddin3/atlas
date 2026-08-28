import 'location_constants.dart';

/// Position utilisateur résolue (GPS, choix manuel, ou repli catalogue).
class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.isFromGps,
    this.contentCityName = '',
    this.countryCode = '',
    this.isResolved = true,
  });

  /// Repli catalogue sans prétendre que l'utilisateur est à Marrakech.
  ///
  /// Les coords Marrakech servent au contenu (lieux, prix), jamais aux
  /// horaires de prière en mode auto (`isResolved == false`).
  static const catalogFallback = UserLocation(
    latitude: LocationConstants.fallbackLatitude,
    longitude: LocationConstants.fallbackLongitude,
    cityName: '',
    contentCityName: LocationConstants.fallbackCity,
    isFromGps: false,
    isResolved: false,
  );

  final double latitude;
  final double longitude;

  /// Ville détectée (GPS) ou choisie (manuel). Vide si auto sans position.
  final String cityName;

  /// Ville à utiliser pour les catalogues (lieux, prix, carte).
  final String contentCityName;

  /// ISO 3166-1 alpha-2 (GPS / géocodage / ville manuelle). Vide si inconnu.
  final String countryCode;

  final bool isFromGps;

  /// `false` en mode auto lorsque GPS / permission / services sont indisponibles.
  final bool isResolved;

  /// Ville affichée comme localisation réelle (jamais le fallback catalogue seul).
  String get displayCityName => cityName.trim();

  /// Ville catalogue : contenu Marrakech si hors zone / non résolu.
  String get catalogCity {
    if (contentCityName.trim().isNotEmpty) return contentCityName;
    if (cityName.trim().isNotEmpty) return cityName;
    return LocationConstants.fallbackCity;
  }

  bool get usesCatalogFallback =>
      catalogCity.isNotEmpty &&
      displayCityName.isNotEmpty &&
      catalogCity.toLowerCase() != displayCityName.toLowerCase();
}
