import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/config/atlas_env.dart';
import 'package:atlas/features/profile/data/profile_preferences_store.dart';
import 'package:atlas/features/profile/data/profile_remote_snapshot.dart';
import 'package:atlas/features/profile/data/supabase_profile_repository.dart';
import 'package:atlas/features/profile/data/syncing_profile_repository.dart';
import 'package:atlas/features/profile/domain/models/user_profile.dart';

void main() {
  group('SyncingProfileRepository', () {
    test('retombe sur le local quand la synchronisation est indisponible', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ProfilePreferencesStore();
      final repository = SyncingProfileRepository(
        store: store,
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: '',
          supabaseAnonKey: '',
        ),
        remote: _FailingRemoteRepository(),
        userIdProvider: () => 'user-1',
      );

      await repository.load();

      expect(repository.profile.firstName, UserProfile.defaultFirstName);
      expect(repository.isLoaded, isTrue);
    });

    test('applique le profil distant sans édition locale', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ProfilePreferencesStore();
      final repository = SyncingProfileRepository(
        store: store,
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: 'https://example.supabase.co',
          supabaseAnonKey: 'anon-key',
        ),
        remote: _StubRemoteRepository(),
        userIdProvider: () => 'user-1',
        syncEnabledOverride: true,
        syncTimeout: const Duration(milliseconds: 100),
      );

      await repository.load();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(repository.profile.firstName, 'Yasmine');
      expect(repository.profile.preferredCity, 'Rabat');
    });

    test('marque sync_pending quand le push distant échoue', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ProfilePreferencesStore();
      final repository = SyncingProfileRepository(
        store: store,
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: 'https://example.supabase.co',
          supabaseAnonKey: 'anon-key',
        ),
        remote: _FailingRemoteRepository(),
        userIdProvider: () => 'user-1',
        syncEnabledOverride: true,
      );

      final saved = await repository.save(
        const UserProfile(
          firstName: 'Salma',
          preferredCity: 'Casablanca',
          language: AtlasLanguage.french,
          userType: AtlasUserType.resident,
        ),
      );

      expect(saved, isTrue);
      final snapshot = await store.loadSnapshot();
      expect(snapshot.syncPending, isTrue);
      expect(snapshot.localUpdatedAt, isNotNull);
    });
  });
}

class _FailingRemoteRepository extends SupabaseProfileRepository {
  _FailingRemoteRepository() : super(clientProvider: () => throw StateError('no client'));

  @override
  Future<ProfileRemoteSnapshot?> fetch(String userId) async {
    throw Exception('network error');
  }

  @override
  Future<void> upsert({
    required String userId,
    required UserProfile profile,
  }) async {
    throw Exception('network error');
  }
}

class _StubRemoteRepository extends SupabaseProfileRepository {
  _StubRemoteRepository() : super(clientProvider: () => throw StateError('no client'));

  @override
  Future<ProfileRemoteSnapshot?> fetch(String userId) async {
    return ProfileRemoteSnapshot(
      profile: const UserProfile(
        firstName: 'Yasmine',
        preferredCity: 'Rabat',
        language: AtlasLanguage.french,
        userType: AtlasUserType.mre,
      ),
      updatedAt: DateTime.utc(2026, 7, 12, 10),
    );
  }

  @override
  Future<void> upsert({
    required String userId,
    required UserProfile profile,
  }) async {}
}
