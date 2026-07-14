/// Résultat d'une action d'authentification.
class AuthActionResult {
  const AuthActionResult._({
    required this.success,
    this.errorMessage,
    this.backendUnavailable = false,
  });

  final bool success;
  final String? errorMessage;
  final bool backendUnavailable;

  factory AuthActionResult.success() {
    return const AuthActionResult._(success: true);
  }

  factory AuthActionResult.failure(String message) {
    return AuthActionResult._(success: false, errorMessage: message);
  }

  factory AuthActionResult.backendUnavailable() {
    return const AuthActionResult._(
      success: false,
      backendUnavailable: true,
      errorMessage: 'Synchronisation cloud indisponible.',
    );
  }
}
