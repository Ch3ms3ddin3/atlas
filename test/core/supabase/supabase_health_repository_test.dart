import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:atlas/core/config/atlas_env.dart';
import 'package:atlas/core/supabase/supabase_health_repository.dart';

void main() {
  group('SupabaseHealthRepository', () {
    test('retourne notConfigured sans variables d\'environnement', () async {
      final repository = SupabaseHealthRepository(
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: '',
          supabaseAnonKey: '',
        ),
      );

      final status = await repository.checkHealth();

      expect(status.isConfigured, isFalse);
      expect(status.isReachable, isFalse);
      expect(status.ok, isFalse);
    });

    test('retourne clientUnavailable si le client n\'est pas initialisé', () async {
      final repository = SupabaseHealthRepository(
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: 'https://example.supabase.co',
          supabaseAnonKey: 'anon-key',
        ),
        clientProvider: _nullClient,
      );

      final status = await repository.checkHealth();

      expect(status.isConfigured, isTrue);
      expect(status.isReachable, isFalse);
      expect(status.errorMessage, isNotNull);
    });

    test('retourne reachable quand la sonde réussit', () async {
      final repository = SupabaseHealthRepository(
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: 'https://example.supabase.co',
          supabaseAnonKey: 'anon-key',
        ),
        clientProvider: () => _FakeSupabaseClient(),
        probe: (_) async => {'slug': 'ping', 'ok': true},
      );

      final status = await repository.checkHealth();

      expect(status.ok, isTrue);
      expect(status.latency, isNotNull);
    });

    test('retourne une erreur quand la sonde échoue', () async {
      final repository = SupabaseHealthRepository(
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: 'https://example.supabase.co',
          supabaseAnonKey: 'anon-key',
        ),
        clientProvider: () => _FakeSupabaseClient(),
        probe: (_) async => throw Exception('network error'),
      );

      final status = await repository.checkHealth();

      expect(status.isConfigured, isTrue);
      expect(status.isReachable, isFalse);
      expect(status.errorMessage, contains('network error'));
    });
  });
}

SupabaseClient? _nullClient() => null;

class _FakeSupabaseClient implements SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
