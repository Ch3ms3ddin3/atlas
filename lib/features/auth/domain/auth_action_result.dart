/// Résultat d'une action d'authentification.
class AuthActionResult {
  const AuthActionResult._({
    required this.success,
    this.errorMessage,
    this.backendUnavailable = false,
    this.requiresEmailConfirmation = false,
  });

  final bool success;
  final String? errorMessage;
  final bool backendUnavailable;

  /// Succès d'inscription / liaison e-mail : confirmation mail encore requise.
  final bool requiresEmailConfirmation;

  factory AuthActionResult.success({
    bool requiresEmailConfirmation = false,
  }) {
    return AuthActionResult._(
      success: true,
      requiresEmailConfirmation: requiresEmailConfirmation,
    );
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
