import 'backend_health_status.dart';

/// Contrat d'accès au contrôle de santé backend — indépendant de Supabase.
abstract class BackendHealthRepository {
  const BackendHealthRepository();

  /// Vérifie la disponibilité du backend sans impacter les fonctionnalités.
  Future<BackendHealthStatus> checkHealth();
}
