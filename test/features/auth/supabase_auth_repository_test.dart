import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/config/atlas_env.dart';
import 'package:atlas/core/supabase/supabase_bootstrap.dart';
import 'package:atlas/features/auth/data/supabase_auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';

void main() {
  tearDown(() {
    SupabaseBootstrap.resetForTest();
  });

  group('SupabaseAuthRepository', () {
    test('expose une session indisponible sans backend', () async {
      final repository = SupabaseAuthRepository(
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: '',
          supabaseAnonKey: '',
        ),
      );

      await repository.load();

      expect(repository.session.kind, AuthSessionKind.unavailable);
      expect(repository.isLoaded, isTrue);
    });

    test('refuse l inscription quand le backend est indisponible', () async {
      final repository = SupabaseAuthRepository(
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: '',
          supabaseAnonKey: '',
        ),
      );

      final result = await repository.signUp(
        email: 'salma@exemple.com',
        password: 'secret12',
      );

      expect(result.success, isFalse);
      expect(result.backendUnavailable, isTrue);
    });
  });
}
