/// Estimation ISO 3166-1 alpha-2 à partir des coordonnées.
///
/// Utilisé seulement si le reverse geocoding n'a pas fourni de pays.
/// Les boîtes sont volontairement conservatrices ; en cas de doute → `null`.
abstract final class AtlasGeoCountry {
  /// Maroc (y compris une approximation du Sahara occidental).
  static const morocco = _Box(
    minLatitude: 20.8,
    maxLatitude: 36.05,
    minLongitude: -17.15,
    maxLongitude: -0.85,
  );

  /// France métropolitaine + Corse.
  static const france = _Box(
    minLatitude: 41.3,
    maxLatitude: 51.15,
    minLongitude: -5.25,
    maxLongitude: 9.7,
  );

  static const algeria = _Box(
    minLatitude: 18.9,
    maxLatitude: 37.15,
    minLongitude: -8.7,
    maxLongitude: 12.05,
  );

  static const tunisia = _Box(
    minLatitude: 30.2,
    maxLatitude: 37.55,
    minLongitude: 7.5,
    maxLongitude: 11.65,
  );

  static const belgium = _Box(
    minLatitude: 49.45,
    maxLatitude: 51.55,
    minLongitude: 2.5,
    maxLongitude: 6.45,
  );

  static const spain = _Box(
    minLatitude: 35.95,
    maxLatitude: 43.85,
    minLongitude: -9.4,
    maxLongitude: 3.35,
  );

  /// Pays le plus probable, ou `null` si hors des zones connues.
  static String? guessIsoCode({
    required double latitude,
    required double longitude,
  }) {
    if (morocco.contains(latitude, longitude)) return 'MA';
    if (tunisia.contains(latitude, longitude)) return 'TN';
    if (belgium.contains(latitude, longitude)) return 'BE';
    if (france.contains(latitude, longitude)) return 'FR';
    if (spain.contains(latitude, longitude)) return 'ES';
    if (algeria.contains(latitude, longitude)) return 'DZ';
    return null;
  }
}

class _Box {
  const _Box({
    required this.minLatitude,
    required this.maxLatitude,
    required this.minLongitude,
    required this.maxLongitude,
  });

  final double minLatitude;
  final double maxLatitude;
  final double minLongitude;
  final double maxLongitude;

  bool contains(double latitude, double longitude) {
    return latitude >= minLatitude &&
        latitude <= maxLatitude &&
        longitude >= minLongitude &&
        longitude <= maxLongitude;
  }
}
