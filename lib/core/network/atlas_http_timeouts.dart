/// Timeouts HTTP partagés (weather, prayer, FX, OSRM, Edge AI).
abstract final class AtlasHttpTimeouts {
  /// GET JSON / APIs courtes.
  static const Duration defaultTimeout = Duration(seconds: 12);

  /// Connexion initiale pour les flux SSE (le stream lui-même reste ouvert).
  static const Duration streamConnectTimeout = Duration(seconds: 20);
}
