import 'package:flutter/foundation.dart';

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
    this.showSocialAuth = false,
    this.showExperimentalSurfaces = false,
    this.showBetaFeedback = true,
  });

  /// Valeurs injectées à la compilation (`--dart-define-from-file`).
  factory AtlasEnv.fromCompileTime() {
    return AtlasEnv(
      environment: AtlasEnvironment.parse(
        const String.fromEnvironment('ATLAS_ENV', defaultValue: 'development'),
      ),
      supabaseUrl: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: '',
      ),
      supabaseAnonKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: '',
      ),
      showSocialAuth: const bool.fromEnvironment(
        'SHOW_SOCIAL_AUTH',
        defaultValue: false,
      ),
      showExperimentalSurfaces: const bool.fromEnvironment(
        'SHOW_EXPERIMENTAL_SURFACES',
        defaultValue: false,
      ),
      showBetaFeedback: const bool.fromEnvironment(
        'SHOW_BETA_FEEDBACK',
        defaultValue: true,
      ),
    );
  }

  final AtlasEnvironment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;

  /// Apple/Google OAuth buttons — off by default for Marrakech private beta.
  final bool showSocialAuth;

  /// Assistant / Itinéraires — off by default for Marrakech private beta.
  /// Implementation remains in the tree; UI entry points are gated.
  final bool showExperimentalSurfaces;

  /// In-app « Signaler » FAB — on by default for private beta (including
  /// profile / release / TestFlight builds).
  final bool showBetaFeedback;

  /// `true` lorsque l'URL et la clé anon publique sont fournies.
  bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  /// Alias explicite pour les checks de bootstrap.
  bool get isConfigured => isSupabaseConfigured;

  /// Staging, production, or release binaries must not ship empty / example keys.
  bool get requiresHardenedSupabaseCredentials {
    if (environment == AtlasEnvironment.staging ||
        environment == AtlasEnvironment.production) {
      return true;
    }
    return kReleaseMode;
  }

  /// Detects empty or example-file placeholders (never treat as production-ready).
  bool get looksLikePlaceholderCredentials {
    final url = supabaseUrl.trim().toLowerCase();
    final key = supabaseAnonKey.trim().toLowerCase();
    if (url.isEmpty || key.isEmpty) return true;
    const urlMarkers = <String>[
      'your-dev-project',
      'your-staging-project',
      'your-production-project',
      'example.supabase.co',
      'your-',
    ];
    for (final marker in urlMarkers) {
      if (url.contains(marker)) return true;
    }
    const keyMarkers = <String>[
      'your-dev-anon-key',
      'your-staging-anon-key',
      'your-production-anon-key',
      'your-anon-key',
      'anon-key',
    ];
    for (final marker in keyMarkers) {
      if (key == marker || key.contains(marker)) return true;
    }
    return false;
  }

  /// Human-readable block reason for release/TestFlight misconfiguration, or null.
  String? get hardenedCredentialsIssue {
    if (!requiresHardenedSupabaseCredentials) return null;
    if (!isConfigured || looksLikePlaceholderCredentials) {
      return 'Configuration Atlas invalide pour ${environment.label}.\n\n'
          'Fournissez de vraies valeurs SUPABASE_URL et SUPABASE_ANON_KEY '
          'via --dart-define-from-file (.env.staging ou .env.production).\n\n'
          'Ne compilez jamais une build TestFlight avec des placeholders '
          'des fichiers .env.*.example.';
    }
    return null;
  }
}
