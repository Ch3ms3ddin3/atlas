import '../location/atlas_city_source.dart';

/// Horloge d'affichage Accueil — auto = appareil, manual = Africa/Casablanca.
abstract final class AtlasDisplayClock {
  static const casablancaTimeZone = 'Africa/Casablanca';

  /// Africa/Casablanca, UTC+1 permanent depuis 2018.
  static DateTime casablancaNow([DateTime? utcNow]) {
    return (utcNow ?? DateTime.now().toUtc()).add(const Duration(hours: 1));
  }

  /// Instant utilisé pour la date / l'heure / le jour civil Accueil.
  static DateTime nowFor({
    required AtlasCitySource citySource,
    DateTime? deviceNow,
    DateTime? utcNow,
  }) {
    if (citySource == AtlasCitySource.manual) {
      return casablancaNow(utcNow ?? deviceNow?.toUtc());
    }
    return deviceNow ?? DateTime.now();
  }

  static String formatHm(DateTime now) {
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Open-Meteo : `auto` suit les coordonnées déjà résolues (GPS ou ville).
  static const openMeteoTimeZone = 'auto';

  /// AlAdhan : `null` en auto (inféré des coordonnées), Casablanca en manuel.
  static String? aladhanTimeZone({required AtlasCitySource citySource}) {
    if (citySource == AtlasCitySource.manual) return casablancaTimeZone;
    return null;
  }
}
