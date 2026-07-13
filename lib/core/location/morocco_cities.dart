import 'location_constants.dart';

/// Ville du Maroc avec coordonnées pour la météo, la prière et les repli GPS.
class MoroccoCity {
  const MoroccoCity({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;
}

/// Villes sélectionnables dans le profil et utilisées comme repli local.
abstract final class MoroccoCities {
  static const marrakech = MoroccoCity(
    name: 'Marrakech',
    latitude: LocationConstants.fallbackLatitude,
    longitude: LocationConstants.fallbackLongitude,
  );

  static const casablanca = MoroccoCity(
    name: 'Casablanca',
    latitude: 33.5731,
    longitude: -7.5898,
  );

  static const rabat = MoroccoCity(
    name: 'Rabat',
    latitude: 34.0209,
    longitude: -6.8416,
  );

  static const fes = MoroccoCity(
    name: 'Fès',
    latitude: 34.0181,
    longitude: -5.0078,
  );

  static const tanger = MoroccoCity(
    name: 'Tanger',
    latitude: 35.7595,
    longitude: -5.8340,
  );

  static const agadir = MoroccoCity(
    name: 'Agadir',
    latitude: 30.4278,
    longitude: -9.5981,
  );

  static const supported = <MoroccoCity>[
    marrakech,
    casablanca,
    rabat,
    fes,
    tanger,
    agadir,
  ];

  static const supportedNames = <String>[
    'Marrakech',
    'Casablanca',
    'Rabat',
    'Fès',
    'Tanger',
    'Agadir',
  ];

  /// Retourne la ville si reconnue, sinon null.
  static MoroccoCity? resolve(String? cityName) {
    if (cityName == null || cityName.trim().isEmpty) return null;
    final normalized = cityName.trim().toLowerCase();
    for (final city in supported) {
      if (city.name.toLowerCase() == normalized) {
        return city;
      }
    }
    return null;
  }

  /// Ville de repli finale — Marrakech.
  static MoroccoCity get fallback => marrakech;
}
