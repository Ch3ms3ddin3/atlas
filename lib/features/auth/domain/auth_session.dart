/// État de session d'authentification exposé à l'UI.
enum AuthSessionKind {
  /// Supabase non configuré ou non initialisé — mode 100 % local.
  unavailable,

  /// Session anonyme Supabase active.
  anonymous,

  /// Compte email / mot de passe connecté.
  signedIn,
}

/// Session courante de l'utilisateur.
class AuthSession {
  const AuthSession({
    required this.kind,
    this.userId,
    this.email,
  });

  const AuthSession.unavailable() : this(kind: AuthSessionKind.unavailable);

  final AuthSessionKind kind;
  final String? userId;
  final String? email;

  bool get isCloudAvailable => kind != AuthSessionKind.unavailable;

  bool get isSignedIn => kind == AuthSessionKind.signedIn;

  bool get isAnonymous => kind == AuthSessionKind.anonymous;
}
