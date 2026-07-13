/// Environnement d'exécution Atlas (dev, staging, production).
enum AtlasEnvironment {
  development,
  staging,
  production;

  static AtlasEnvironment parse(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'staging':
        return AtlasEnvironment.staging;
      case 'production':
      case 'prod':
        return AtlasEnvironment.production;
      case 'development':
      case 'dev':
      default:
        return AtlasEnvironment.development;
    }
  }

  String get label => switch (this) {
        AtlasEnvironment.development => 'development',
        AtlasEnvironment.staging => 'staging',
        AtlasEnvironment.production => 'production',
      };
}

/// Configuration compile-time lue via `--dart-define-from-file`.
///
/// Ne jamais y placer la clé service-role Supabase.
class AtlasEnv {
  const AtlasEnv({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  /// Valeurs injectées à la compilation (`--dart-define-from-file`).
  factory AtlasEnv.fromCompileTime() {
    return AtlasEnv(
      environment: AtlasEnvironment.parse(
        const String.fromEnvironment('ATLAS_ENV', defaultValue: 'development'),
      ),
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
      supabaseAnonKey:
          const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
    );
  }

  final AtlasEnvironment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;

  /// `true` lorsque l'URL et la clé anon publique sont fournies.
  bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  /// Alias explicite pour les checks de bootstrap.
  bool get isConfigured => isSupabaseConfigured;
}
