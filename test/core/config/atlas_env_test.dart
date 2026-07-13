import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/config/atlas_env.dart';

void main() {
  group('AtlasEnv.fromCompileTime', () {
    test('défaut sur development sans variables', () {
      const env = AtlasEnv(
        environment: AtlasEnvironment.development,
        supabaseUrl: '',
        supabaseAnonKey: '',
      );

      expect(env.environment, AtlasEnvironment.development);
      expect(env.isConfigured, isFalse);
    });

    test('isConfigured exige URL et clé anon', () {
      const partial = AtlasEnv(
        environment: AtlasEnvironment.staging,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: '',
      );
      const complete = AtlasEnv(
        environment: AtlasEnvironment.staging,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'anon-key',
      );

      expect(partial.isConfigured, isFalse);
      expect(complete.isConfigured, isTrue);
      expect(complete.environment.label, 'staging');
    });
  });

  group('AtlasEnvironment.parse', () {
    test('accepte les alias courants', () {
      expect(AtlasEnvironment.parse('dev'), AtlasEnvironment.development);
      expect(AtlasEnvironment.parse('staging'), AtlasEnvironment.staging);
      expect(AtlasEnvironment.parse('prod'), AtlasEnvironment.production);
      expect(AtlasEnvironment.parse('production'), AtlasEnvironment.production);
    });
  });
}
