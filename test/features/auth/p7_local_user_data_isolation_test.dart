import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/config/atlas_env.dart';
import 'package:atlas/features/admission_temporaire/data/at_preferences_store.dart';
import 'package:atlas/features/auth/data/local_user_data_isolator.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/favorites/data/favorites_preferences_store.dart';
import 'package:atlas/features/favorites/data/supabase_favorites_repository.dart';
import 'package:atlas/features/favorites/data/syncing_favorites_repository.dart';
import 'package:atlas/features/favorites/domain/favorite_entity_type.dart';
import 'package:atlas/features/favorites/domain/models/favorite_record.dart';
import 'package:atlas/features/itineraries/data/itinerary_local_store.dart';
import 'package:atlas/features/profile/data/profile_preferences_store.dart';
import 'package:atlas/features/profile/domain/models/user_profile.dart';
import 'package:atlas/features/sync/data/syncing_user_preferences_repository.dart';
import 'package:atlas/features/sync/domain/cloud_sync_status.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaceBrowseFilters.resetForTest();
  });

  tearDown(PlaceBrowseFilters.resetForTest);

  group('LocalUserDataIsolator.shouldClearLocal', () {
    test('première liaison : pas de clear', () {
      expect(
        LocalUserDataIsolator.shouldClearLocal(
          previousKind: null,
          previousUserId: null,
          nextKind: AuthSessionKind.anonymous,
          nextUserId: 'anon-1',
        ),
        isFalse,
      );
    });

    test('unavailable → anonymous : conserve le local invité', () {
      expect(
        LocalUserDataIsolator.shouldClearLocal(
          previousKind: AuthSessionKind.unavailable,
          previousUserId: null,
          nextKind: AuthSessionKind.anonymous,
          nextUserId: 'anon-1',
        ),
        isFalse,
      );
    });

    test('logout signedIn → anonymous : clear', () {
      expect(
        LocalUserDataIsolator.shouldClearLocal(
          previousKind: AuthSessionKind.signedIn,
          previousUserId: 'user-a',
          nextKind: AuthSessionKind.anonymous,
          nextUserId: 'anon-2',
        ),
        isTrue,
      );
    });

    test('switch signedIn A → signedIn B : clear', () {
      expect(
        LocalUserDataIsolator.shouldClearLocal(
          previousKind: AuthSessionKind.signedIn,
          previousUserId: 'user-a',
          nextKind: AuthSessionKind.signedIn,
          nextUserId: 'user-b',
        ),
        isTrue,
      );
    });

    test('login anonymous → signedIn : clear (pas de push guest→compte)', () {
      expect(
        LocalUserDataIsolator.shouldClearLocal(
          previousKind: AuthSessionKind.anonymous,
          previousUserId: 'anon-1',
          nextKind: AuthSessionKind.signedIn,
          nextUserId: 'user-a',
        ),
        isTrue,
      );
    });

    test('même identité : pas de clear', () {
      expect(
        LocalUserDataIsolator.shouldClearLocal(
          previousKind: AuthSessionKind.signedIn,
          previousUserId: 'user-a',
          nextKind: AuthSessionKind.signedIn,
          nextUserId: 'user-a',
        ),
        isFalse,
      );
    });
  });

  group('LocalUserDataIsolator.clearPersistedUserData', () {
    test('efface favoris, profil, AT, itinéraires et filtres', () async {
      const favorites = FavoritesPreferencesStore();
      await favorites.saveRecords([
        FavoriteRecord(
          entityType: FavoriteEntityType.place,
          entitySlug: 'place-jardin-majorelle',
          isActive: true,
          updatedAt: DateTime.utc(2026, 8, 1),
        ),
      ]);
      await favorites.setSyncPending(true);

      const profile = ProfilePreferencesStore();
      await profile.saveProfile(
        const UserProfile(
          firstName: 'Alice',
          preferredCity: 'Casablanca',
          language: AtlasLanguage.french,
          userType: AtlasUserType.mre,
        ),
        localUpdatedAt: DateTime.utc(2026, 8, 1),
      );

      const at = AtPreferencesStore();
      await at.setNotificationsEnabled(true);
      await at.setSyncPending(true);

      const trips = ItineraryLocalStore();
      await trips.setSyncPending(true);

      PlaceBrowseFilters.instance.update(
        cityName: 'Marrakech',
        favoritesOnly: true,
      );

      await LocalUserDataIsolator.clearPersistedUserData();

      final favSnap = await favorites.loadSnapshot();
      expect(favSnap.records, isEmpty);
      expect(favSnap.syncPending, isFalse);

      final profileSnap = await profile.loadSnapshot();
      expect(profileSnap.profile.firstName, UserProfile.defaultFirstName);
      expect(profileSnap.syncPending, isFalse);

      final atSnap = await at.loadSnapshot();
      expect(atSnap.notificationsEnabled, isFalse);
      expect(atSnap.syncPending, isFalse);

      expect(await trips.isSyncPending(), isFalse);
      expect(PlaceBrowseFilters.instance.cityName, isEmpty);
      expect(PlaceBrowseFilters.instance.favoritesOnly, isFalse);
    });
  });

  group('sync gate signed-in only', () {
    test('favoris anonymes : pas de sync même avec userId', () async {
      SharedPreferences.setMockInitialValues({});
      final remote = _RecordingFavoritesRemote();
      final repository = SyncingFavoritesRepository(
        store: const FavoritesPreferencesStore(),
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: 'https://example.supabase.co',
          supabaseAnonKey: 'anon-key',
        ),
        remote: remote,
        userIdProvider: () => 'anon-user',
        isSignedInProvider: () => false,
      );

      await repository.addFavorite(
        entityType: FavoriteEntityType.place,
        entitySlug: 'place-jardin-majorelle',
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(remote.fetchCalls, 0);
      expect(remote.upsertCalls, 0);
      expect(repository.isFavorite(
        entityType: FavoriteEntityType.place,
        entitySlug: 'place-jardin-majorelle',
      ), isTrue);
    });

    test('préférences : statut local honnête hors compte', () async {
      final repository = SyncingUserPreferencesRepository(
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: 'https://example.supabase.co',
          supabaseAnonKey: 'anon-key',
        ),
        userIdProvider: () => 'anon-user',
        isSignedInProvider: () => false,
      );

      await repository.load();
      expect(repository.status.phase, CloudSyncPhase.offline);
      expect(repository.status.labelFr, contains('Mode local'));
      expect(repository.status.labelFr, isNot(contains('À jour')));
    });

    test('label synced ne prétend plus un état global', () {
      const status = CloudSyncStatus(phase: CloudSyncPhase.synced);
      expect(status.labelFr, 'Préférences synchronisées');
      expect(status.labelFr, isNot(equals('À jour')));
    });
  });

  group('isolation A → B sans push de A', () {
    test('après clear, sync B ne voit plus les records locaux de A', () async {
      const store = FavoritesPreferencesStore();
      await store.saveRecords([
        FavoriteRecord(
          entityType: FavoriteEntityType.place,
          entitySlug: 'place-from-user-a',
          isActive: true,
          updatedAt: DateTime.utc(2026, 8, 1),
        ),
      ]);
      await store.setSyncPending(true);

      await LocalUserDataIsolator.clearPersistedUserData();

      final remote = _RecordingFavoritesRemote();
      final repository = SyncingFavoritesRepository(
        store: store,
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: 'https://example.supabase.co',
          supabaseAnonKey: 'anon-key',
        ),
        remote: remote,
        userIdProvider: () => 'user-b',
        isSignedInProvider: () => true,
        syncEnabledOverride: true,
        syncTimeout: const Duration(milliseconds: 50),
      );

      await repository.load();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(repository.activeFavorites, isEmpty);
      expect(remote.upsertedSlugs, isEmpty);
      expect(remote.fetchCalls, greaterThan(0));
    });
  });
}

class _RecordingFavoritesRemote extends SupabaseFavoritesRepository {
  int fetchCalls = 0;
  int upsertCalls = 0;
  final List<String> upsertedSlugs = [];

  @override
  Future<List<FavoriteRecord>> fetch(String userId) async {
    fetchCalls += 1;
    return const [];
  }

  @override
  Future<void> upsert({
    required String userId,
    required FavoriteRecord record,
  }) async {
    upsertCalls += 1;
    upsertedSlugs.add(record.entitySlug);
  }
}
