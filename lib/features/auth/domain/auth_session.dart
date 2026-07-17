/// Fournisseur d'identité connecté au compte Atlas.
enum AuthProviderKind {
  email,
  apple,
  google,
}

extension AuthProviderKindLabels on AuthProviderKind {
  String get label => switch (this) {
        AuthProviderKind.email => 'E-mail',
        AuthProviderKind.apple => 'Apple',
        AuthProviderKind.google => 'Google',
      };

  static AuthProviderKind? fromSupabaseId(String? id) {
    return switch (id) {
      'email' => AuthProviderKind.email,
      'apple' => AuthProviderKind.apple,
      'google' => AuthProviderKind.google,
      _ => null,
    };
  }
}

/// État de session d'authentification exposé à l'UI.
enum AuthSessionKind {
  /// Supabase non configuré ou non initialisé — mode 100 % local.
  unavailable,

  /// Session anonyme Supabase active.
  anonymous,

  /// Compte authentifié (e-mail ou OAuth).
  signedIn,
}

/// Session courante de l'utilisateur.
class AuthSession {
  const AuthSession({
    required this.kind,
    this.userId,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.providers = const [],
  });

  const AuthSession.unavailable() : this(kind: AuthSessionKind.unavailable);

  final AuthSessionKind kind;
  final String? userId;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final List<AuthProviderKind> providers;

  bool get isCloudAvailable => kind != AuthSessionKind.unavailable;

  bool get isSignedIn => kind == AuthSessionKind.signedIn;

  bool get isAnonymous => kind == AuthSessionKind.anonymous;
}
