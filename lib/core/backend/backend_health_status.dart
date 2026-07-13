/// Résultat d'un ping backend — utilisé par le bootstrap et les tests.
class BackendHealthStatus {
  const BackendHealthStatus({
    required this.isConfigured,
    required this.isReachable,
    this.latency,
    this.errorMessage,
  });

  /// Backend non configuré (variables d'environnement absentes).
  factory BackendHealthStatus.notConfigured() {
    return const BackendHealthStatus(
      isConfigured: false,
      isReachable: false,
    );
  }

  /// Client backend non initialisé (bootstrap ignoré ou échoué).
  factory BackendHealthStatus.clientUnavailable({String? errorMessage}) {
    return BackendHealthStatus(
      isConfigured: true,
      isReachable: false,
      errorMessage: errorMessage,
    );
  }

  final bool isConfigured;
  final bool isReachable;
  final Duration? latency;
  final String? errorMessage;

  bool get ok => isConfigured && isReachable;
}
