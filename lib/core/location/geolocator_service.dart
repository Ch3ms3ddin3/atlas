import 'package:geolocator/geolocator.dart';

/// Encapsule geolocator — permission et position courante.
class GeolocatorService {
  const GeolocatorService();

  static const _positionTimeout = Duration(seconds: 10);

  /// `true` si une permission d'utilisation a déjà été accordée (sans demander).
  Future<bool> hasGrantedPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Tente d'obtenir la position ; renvoie null si refusé ou indisponible.
  Future<Position?> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: _positionTimeout,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
