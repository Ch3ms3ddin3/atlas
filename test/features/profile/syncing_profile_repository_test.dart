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
    test(
      'retombe sur le local quand la synchronisation est indisponible',
      () async {
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
      },
    );

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

    test('save pousse displayName et avatarUrl sans les effacer', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ProfilePreferencesStore();
      final remote = _CapturingRemoteRepository();
      final repository = SyncingProfileRepository(
        store: store,
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: 'https://example.supabase.co',
          supabaseAnonKey: 'anon-key',
        ),
        remote: remote,
        userIdProvider: () => 'user-1',
        syncEnabledOverride: true,
      );

      final saved = await repository.save(
        const UserProfile(
          firstName: 'Salma',
          preferredCity: 'Casablanca',
          language: AtlasLanguage.french,
          userType: AtlasUserType.resident,
          displayName: 'Salma Benali',
          avatarUrl: 'https://cdn.example/salma.png',
        ),
      );
      expect(saved, isTrue);
      expect(repository.profile.displayName, 'Salma Benali');
      expect(repository.profile.avatarUrl, 'https://cdn.example/salma.png');

      // Same path as ProfilePage: edit required fields via copyWith.
      final edited = await repository.save(
        repository.profile.copyWith(preferredCity: 'Rabat'),
      );
      expect(edited, isTrue);
      expect(repository.profile.displayName, 'Salma Benali');
      expect(repository.profile.avatarUrl, 'https://cdn.example/salma.png');
      expect(remote.lastUpserted?.displayName, 'Salma Benali');
      expect(remote.lastUpserted?.avatarUrl, 'https://cdn.example/salma.png');
      expect(remote.lastUpserted?.preferredCity, 'Rabat');

      final snapshot = await store.loadSnapshot();
      expect(snapshot.profile.displayName, 'Salma Benali');
      expect(snapshot.profile.avatarUrl, 'https://cdn.example/salma.png');
      expect(snapshot.profile.preferredCity, 'Rabat');
    });

    test(
      'ville sauvée pendant un fetch distant n\'est pas écrasée au push',
      () async {
        SharedPreferences.setMockInitialValues({});
        final store = ProfilePreferencesStore();
        await store.saveProfile(
          const UserProfile(
            firstName: 'Salma',
            preferredCity: 'Marrakech',
            language: AtlasLanguage.french,
            userType: AtlasUserType.resident,
            displayName: 'Salma Benali',
            avatarUrl: 'https://cdn.example/salma.png',
          ),
          localUpdatedAt: DateTime.utc(2026, 8, 1),
        );

        final remote = _DelayedRemoteRepository(
          delay: const Duration(milliseconds: 80),
          remote: ProfileRemoteSnapshot(
            profile: const UserProfile(
              firstName: 'Salma',
              preferredCity: 'Marrakech',
              language: AtlasLanguage.french,
              userType: AtlasUserType.resident,
              displayName: 'Salma Benali',
              avatarUrl: 'https://cdn.example/salma.png',
            ),
            updatedAt: DateTime.utc(2026, 7, 1),
          ),
        );

        final repository = SyncingProfileRepository(
          store: store,
          env: const AtlasEnv(
            environment: AtlasEnvironment.development,
            supabaseUrl: 'https://example.supabase.co',
            supabaseAnonKey: 'anon-key',
          ),
          remote: remote,
          userIdProvider: () => 'user-1',
          syncEnabledOverride: true,
          syncTimeout: const Duration(seconds: 2),
        );

        // Start load → background fetch begins with Marrakech snapshot.
        final loadFuture = repository.load();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // User changes city while fetch is still in flight (ProfilePage save).
        final saved = await repository.save(
          repository.profile.copyWith(preferredCity: 'Casablanca'),
        );
        expect(saved, isTrue);
        expect(repository.profile.preferredCity, 'Casablanca');

        await loadFuture;
        // Allow background sync to finish merge/push after delayed fetch.
        await Future<void>.delayed(const Duration(milliseconds: 120));

        expect(repository.profile.preferredCity, 'Casablanca');
        expect(repository.profile.displayName, 'Salma Benali');
        expect(repository.profile.avatarUrl, 'https://cdn.example/salma.png');

        final snapshot = await store.loadSnapshot();
        expect(snapshot.profile.preferredCity, 'Casablanca');
        expect(snapshot.profile.firstName, 'Salma');
        expect(snapshot.profile.displayName, 'Salma Benali');

        // Must push the post-save city, never the stale load-time Marrakech.
        expect(remote.lastUpserted, isNotNull);
        expect(remote.lastUpserted!.preferredCity, 'Casablanca');
        expect(remote.upsertedCities, isNotEmpty);
        expect(
          remote.upsertedCities.every((city) => city == 'Casablanca'),
          isTrue,
        );

        // Cold-start style reload must keep the saved city.
        final reloaded = SyncingProfileRepository(
          store: store,
          env: const AtlasEnv(
            environment: AtlasEnvironment.development,
            supabaseUrl: '',
            supabaseAnonKey: '',
          ),
          remote: _FailingRemoteRepository(),
          userIdProvider: () => null,
        );
        await reloaded.load();
        expect(reloaded.profile.preferredCity, 'Casablanca');
        expect(reloaded.profile.firstName, 'Salma');
        expect(reloaded.profile.displayName, 'Salma Benali');
        expect(reloaded.profile.avatarUrl, 'https://cdn.example/salma.png');
      },
    );

    test(
      'save refuse un profil invalide sans écraser l\'identité locale',
      () async {
        SharedPreferences.setMockInitialValues({});
        final store = ProfilePreferencesStore();
        await store.saveProfile(
          const UserProfile(
            firstName: 'Salma',
            preferredCity: 'Casablanca',
            language: AtlasLanguage.french,
            userType: AtlasUserType.resident,
            displayName: 'Salma Benali',
            avatarUrl: 'https://cdn.example/salma.png',
          ),
          localUpdatedAt: DateTime.utc(2026, 8, 11),
        );

        final repository = SyncingProfileRepository(
          store: store,
          env: const AtlasEnv(
            environment: AtlasEnvironment.development,
            supabaseUrl: '',
            supabaseAnonKey: '',
          ),
          remote: _FailingRemoteRepository(),
          userIdProvider: () => null,
        );
        await repository.load();

        final saved = await repository.save(
          repository.profile.copyWith(firstName: '   '),
        );

        expect(saved, isFalse);
        expect(repository.profile.displayName, 'Salma Benali');
        expect(repository.profile.avatarUrl, 'https://cdn.example/salma.png');
        expect(repository.profile.firstName, 'Salma');
        expect(repository.profile.preferredCity, 'Casablanca');
      },
    );
  });
}

class _FailingRemoteRepository extends SupabaseProfileRepository {
  _FailingRemoteRepository()
    : super(clientProvider: () => throw StateError('no client'));

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
  _StubRemoteRepository()
    : super(clientProvider: () => throw StateError('no client'));

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

class _CapturingRemoteRepository extends SupabaseProfileRepository {
  _CapturingRemoteRepository()
    : super(clientProvider: () => throw StateError('no client'));

  UserProfile? lastUpserted;

  @override
  Future<ProfileRemoteSnapshot?> fetch(String userId) async => null;

  @override
  Future<void> upsert({
    required String userId,
    required UserProfile profile,
  }) async {
    lastUpserted = profile;
  }
}

class _DelayedRemoteRepository extends SupabaseProfileRepository {
  _DelayedRemoteRepository({
    required this.delay,
    required this.remote,
  }) : super(clientProvider: () => throw StateError('no client'));

  final Duration delay;
  final ProfileRemoteSnapshot remote;
  UserProfile? lastUpserted;
  final List<String> upsertedCities = <String>[];

  @override
  Future<ProfileRemoteSnapshot?> fetch(String userId) async {
    await Future<void>.delayed(delay);
    return remote;
  }

  @override
  Future<void> upsert({
    required String userId,
    required UserProfile profile,
  }) async {
    upsertedCities.add(profile.preferredCity);
    lastUpserted = profile;
  }
}
