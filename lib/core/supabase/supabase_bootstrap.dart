import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/atlas_env.dart';

/// Résultat de l'initialisation Supabase au démarrage.
class SupabaseBootstrapResult {
  const SupabaseBootstrapResult({
    required this.status,
    this.anonymousSessionEnabled = false,
    this.errorMessage,
  });

  final SupabaseBootstrapStatus status;
  final bool anonymousSessionEnabled;
  final String? errorMessage;

  bool get isReady => status == SupabaseBootstrapStatus.ready;
}

enum SupabaseBootstrapStatus {
  skipped,
  ready,
  failed,
}

/// Initialise Supabase et une session anonyme silencieuse si configuré.
abstract final class SupabaseBootstrap {
  static bool _initialized = false;

  /// `true` après une initialisation Supabase réussie dans cette session.
  static bool get isInitialized => _initialized;

  /// Client Supabase courant, ou `null` si non initialisé.
  static SupabaseClient? clientOrNull() {
    if (!_initialized) return null;
    return Supabase.instance.client;
  }

  /// Initialise Supabase sans bloquer le démarrage de l'app en cas d'échec.
  static Future<SupabaseBootstrapResult> initialize({
    AtlasEnv? env,
  }) async {
    final config = env ?? AtlasEnv.fromCompileTime();

    if (!config.isConfigured) {
      if (kDebugMode) {
        debugPrint(
          '[Atlas] Supabase ignoré — variables SUPABASE_URL / '
          'SUPABASE_ANON_KEY absentes (${config.environment.label}).',
        );
      }
      return const SupabaseBootstrapResult(
        status: SupabaseBootstrapStatus.skipped,
      );
    }

    try {
      // detectSessionInUri: true (défaut) — observe les deep links OAuth /
      // reset password via app_links (schéma io.supabase.atlas).
      await Supabase.initialize(
        url: config.supabaseUrl,
        publishableKey: config.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          detectSessionInUri: true,
        ),
      );
      _initialized = true;

      final anonymousEnabled = await _ensureAnonymousSession();

      if (kDebugMode) {
        debugPrint(
          '[Atlas] Supabase prêt (${config.environment.label}) — '
          'session anonyme: ${anonymousEnabled ? 'active' : 'indisponible'}.',
        );
      }

      return SupabaseBootstrapResult(
        status: SupabaseBootstrapStatus.ready,
        anonymousSessionEnabled: anonymousEnabled,
      );
    } catch (error) {
      _initialized = false;
      if (kDebugMode) {
        debugPrint('[Atlas] Supabase indisponible — repli local actif: $error');
      }
      return SupabaseBootstrapResult(
        status: SupabaseBootstrapStatus.failed,
        errorMessage: error.toString(),
      );
    }
  }

  /// Crée une session anonyme si aucune session n'existe déjà.
  static Future<bool> _ensureAnonymousSession() async {
    final client = clientOrNull();
    if (client == null) return false;

    if (client.auth.currentSession != null) {
      return client.auth.currentUser?.isAnonymous ?? false;
    }

    try {
      await client.auth.signInAnonymously();
      return client.auth.currentUser?.isAnonymous ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Réinitialise l'état interne — réservé aux tests.
  @visibleForTesting
  static void resetForTest() {
    _initialized = false;
  }
}
