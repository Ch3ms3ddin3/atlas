import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/backend_health_repository.dart';
import '../backend/backend_health_status.dart';
import '../config/atlas_env.dart';
import 'supabase_bootstrap.dart';

/// Implémentation Supabase du contrôle de santé backend.
class SupabaseHealthRepository implements BackendHealthRepository {
  SupabaseHealthRepository({
    AtlasEnv? env,
    SupabaseClient? Function()? clientProvider,
    Future<Map<String, dynamic>> Function(SupabaseClient client)? probe,
  })  : _env = env ?? AtlasEnv.fromCompileTime(),
        _clientProvider = clientProvider ?? SupabaseBootstrap.clientOrNull,
        _probe = probe ?? _defaultProbe;

  final AtlasEnv _env;
  final SupabaseClient? Function()? _clientProvider;
  final Future<Map<String, dynamic>> Function(SupabaseClient client) _probe;

  static Future<Map<String, dynamic>> _defaultProbe(SupabaseClient client) {
    return client
        .from('app_health')
        .select('slug, ok, checked_at')
        .eq('slug', 'ping')
        .single();
  }

  @override
  Future<BackendHealthStatus> checkHealth() async {
    if (!_env.isConfigured) {
      return BackendHealthStatus.notConfigured();
    }

    final client = _clientProvider?.call();
    if (client == null) {
      return BackendHealthStatus.clientUnavailable(
        errorMessage: 'Client Supabase non initialisé.',
      );
    }

    final stopwatch = Stopwatch()..start();
    try {
      await _probe(client);
      stopwatch.stop();
      return BackendHealthStatus(
        isConfigured: true,
        isReachable: true,
        latency: stopwatch.elapsed,
      );
    } catch (error) {
      stopwatch.stop();
      return BackendHealthStatus(
        isConfigured: true,
        isReachable: false,
        latency: stopwatch.elapsed,
        errorMessage: error.toString(),
      );
    }
  }
}
