import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Encapsule geolocator — permission et position courante.
class GeolocatorService {
  const GeolocatorService();

  static const _positionTimeout = Duration(seconds: 10);

  /// Une seule invite automatique par session (pas de boucle après refus).
  static bool _didRequestPermission = false;

  /// `true` si une permission d'utilisation a déjà été accordée (sans demander).
  Future<bool> hasGrantedPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Tente d'obtenir la position ; renvoie null si refusé ou indisponible.
  ///
  /// [userInitiated] : tap explicite (ex. « Près de moi ») — peut redemander
  /// si le statut est encore `denied`. Les appels automatiques n'invitent
  /// qu'une fois par session.
  Future<Position?> getCurrentPosition({bool userInitiated = false}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return null;
    }
    if (permission == LocationPermission.denied) {
      if (!userInitiated && _didRequestPermission) {
        return null;
      }
      if (!userInitiated) {
        _didRequestPermission = true;
      }
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

  /// Relance l'invite automatique (tests).
  @visibleForTesting
  static void resetPermissionPromptForTest() {
    _didRequestPermission = false;
  }
}
