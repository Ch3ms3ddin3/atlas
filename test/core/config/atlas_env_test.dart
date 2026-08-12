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

    test('showSocialAuth est false par défaut', () {
      const env = AtlasEnv(
        environment: AtlasEnvironment.development,
        supabaseUrl: '',
        supabaseAnonKey: '',
      );
      expect(env.showSocialAuth, isFalse);
    });

    test('showExperimentalSurfaces est false par défaut', () {
      const env = AtlasEnv(
        environment: AtlasEnvironment.development,
        supabaseUrl: '',
        supabaseAnonKey: '',
      );
      expect(env.showExperimentalSurfaces, isFalse);
    });

    test('showBetaFeedback est true par défaut', () {
      const env = AtlasEnv(
        environment: AtlasEnvironment.development,
        supabaseUrl: '',
        supabaseAnonKey: '',
      );
      expect(env.showBetaFeedback, isTrue);
    });

    test('isConfigured exige URL et clé anon', () {
      const partial = AtlasEnv(
        environment: AtlasEnvironment.staging,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: '',
      );
      const complete = AtlasEnv(
        environment: AtlasEnvironment.staging,
        supabaseUrl: 'https://abcdefgh.supabase.co',
        supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test',
      );

      expect(partial.isConfigured, isFalse);
      expect(complete.isConfigured, isTrue);
      expect(complete.environment.label, 'staging');
      expect(complete.looksLikePlaceholderCredentials, isFalse);
    });

    test('example.supabase.co est traité comme placeholder', () {
      const env = AtlasEnv(
        environment: AtlasEnvironment.staging,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test',
      );
      expect(env.looksLikePlaceholderCredentials, isTrue);
      expect(env.hardenedCredentialsIssue, isNotNull);
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
