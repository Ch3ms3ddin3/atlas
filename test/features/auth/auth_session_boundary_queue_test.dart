import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/config/atlas_env.dart';
import 'package:atlas/core/notifications/notification_preferences_store.dart';
import 'package:atlas/core/notifications/prayer_notification_lead_time.dart';
import 'package:atlas/features/auth/data/auth_session_boundary_controller.dart';
import 'package:atlas/features/auth/data/auth_sync_identity.dart';
import 'package:atlas/features/auth/data/local_user_data_isolator.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/favorites/data/favorites_preferences_store.dart';
import 'package:atlas/features/favorites/data/supabase_favorites_repository.dart';
import 'package:atlas/features/favorites/data/syncing_favorites_repository.dart';
import 'package:atlas/features/favorites/domain/favorite_entity_type.dart';
import 'package:atlas/features/favorites/domain/models/favorite_record.dart';
import 'package:atlas/features/profile/data/profile_preferences_store.dart';
import 'package:atlas/features/profile/data/profile_remote_snapshot.dart';
import 'package:atlas/features/profile/data/supabase_profile_repository.dart';
import 'package:atlas/features/profile/data/syncing_profile_repository.dart';
import 'package:atlas/features/profile/domain/models/user_profile.dart';
import 'package:atlas/features/sync/data/supabase_user_preferences_repository.dart';
import 'package:atlas/features/sync/data/syncing_user_preferences_repository.dart';
import 'package:atlas/features/sync/data/user_preferences_store.dart';
import 'package:atlas/features/sync/data/user_preferences_sync_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthSyncIdentity', () {
    test('isStillCurrent when provider unchanged', () {
      expect(
        AuthSyncIdentity.isStillCurrent(
          capturedUserId: 'user-a',
          userIdProvider: () => 'user-a',
        ),
        isTrue,
      );
    });

    test('isStillCurrent false after A → B', () {
      var current = 'user-a';
      expect(
        AuthSyncIdentity.isStillCurrent(
          capturedUserId: 'user-a',
          userIdProvider: () => current,
        ),
        isTrue,
      );
      current = 'user-b';
      expect(
        AuthSyncIdentity.isStillCurrent(
          capturedUserId: 'user-a',
          userIdProvider: () => current,
        ),
        isFalse,
      );
    });

    test('isStillCurrent false after sign-out to anonymous', () {
      expect(
        AuthSyncIdentity.isStillCurrent(
          capturedUserId: 'user-a',
          userIdProvider: () => 'anon-after',
        ),
        isFalse,
      );
    });
  });

  group('AuthSessionBoundaryController queue/replay', () {
    late AuthSession session;
    late List<String> appliedUserIds;
    late List<String> clearedFor;
    late Completer<void> holdReload;

    AuthSessionBoundaryController buildController() {
      return AuthSessionBoundaryController(
        sessionProvider: () => session,
        loadBoundIdentity: () async => BoundLocalIdentity(
          kind: AuthSessionKind.signedIn,
          userId: appliedUserIds.isEmpty ? 'user-a' : appliedUserIds.last,
        ),
        saveBoundIdentity: ({required kind, required userId}) async {
          appliedUserIds.add(userId ?? 'null');
        },
        clearPersistedUserData: () async {
          clearedFor.add(session.userId ?? 'null');
        },
        shouldClearLocal: ({
          required previousKind,
          required previousUserId,
          required nextKind,
          required nextUserId,
        }) {
          return LocalUserDataIsolator.shouldClearLocal(
            previousKind: previousKind,
            previousUserId: previousUserId,
            nextKind: nextKind,
            nextUserId: nextUserId,
          );
        },
        reloadUserScopedData: () async {
          await holdReload.future;
        },
      );
    }

    setUp(() {
      session = const AuthSession(
        kind: AuthSessionKind.signedIn,
        userId: 'user-a',
        email: 'a@example.com',
      );
      appliedUserIds = <String>[];
      clearedFor = <String>[];
      holdReload = Completer<void>();
    });

    test(
      'rapid A → B during in-flight boundary applies B, not dropped A',
      () async {
        final controller = buildController();

        final first = controller.handleSessionChanged();
        await Future<void>.delayed(Duration.zero);
        expect(controller.isInProgress, isTrue);

        // Mid-flight: switch to B (would previously be dropped).
        session = const AuthSession(
          kind: AuthSessionKind.signedIn,
          userId: 'user-b',
          email: 'b@example.com',
        );
        final second = controller.handleSessionChanged();
        expect(controller.isReplayPending, isTrue);

        holdReload.complete();
        await Future.wait([first, second]);

        expect(appliedUserIds, ['user-a', 'user-b']);
        expect(clearedFor, contains('user-b'));
        expect(controller.boundUserId, 'user-b');
        expect(controller.isInProgress, isFalse);
        expect(controller.isReplayPending, isFalse);
      },
    );

    test(
      'sign-out during slow reload clears then binds anonymous',
      () async {
        final controller = buildController();

        final first = controller.handleSessionChanged();
        await Future<void>.delayed(Duration.zero);

        session = const AuthSession(
          kind: AuthSessionKind.anonymous,
          userId: 'anon-after-logout',
        );
        final second = controller.handleSessionChanged();

        holdReload.complete();
        await Future.wait([first, second]);

        expect(appliedUserIds.last, 'anon-after-logout');
        expect(controller.boundAuthKind, AuthSessionKind.anonymous);
        expect(clearedFor, isNotEmpty);
      },
    );

    test(
      'three rapid switches coalesce to final session only after drain',
      () async {
        final controller = buildController();

        final a = controller.handleSessionChanged();
        await Future<void>.delayed(Duration.zero);

        session = const AuthSession(
          kind: AuthSessionKind.signedIn,
          userId: 'user-b',
        );
        unawaited(controller.handleSessionChanged());
        session = const AuthSession(
          kind: AuthSessionKind.signedIn,
          userId: 'user-c',
        );
        unawaited(controller.handleSessionChanged());

        holdReload.complete();
        await a;
        // Allow nested drain to finish.
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(appliedUserIds.last, 'user-c');
        expect(controller.boundUserId, 'user-c');
      },
    );
  });

  group('Stale sync abort after identity change', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'profile remote apply aborted when A → B mid-fetch',
      () async {
        var currentUserId = 'user-a';
        final store = const ProfilePreferencesStore();
        final remote = _DelayedProfileRemote(
          delay: const Duration(milliseconds: 80),
          remote: ProfileRemoteSnapshot(
            profile: const UserProfile(
              firstName: 'Alice',
              preferredCity: 'Casablanca',
              language: AtlasLanguage.french,
              userType: AtlasUserType.mre,
            ),
            updatedAt: DateTime.utc(2026, 8, 1),
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
          userIdProvider: () => currentUserId,
          isSignedInProvider: () => true,
          syncEnabledOverride: true,
          syncTimeout: const Duration(seconds: 2),
        );

        final loadFuture = repository.load();
        await Future<void>.delayed(const Duration(milliseconds: 10));
        currentUserId = 'user-b';
        await LocalUserDataIsolator.clearPersistedUserData();
        await loadFuture;
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final snapshot = await store.loadSnapshot();
        expect(snapshot.profile.firstName, isNot('Alice'));
        expect(snapshot.profile.firstName, UserProfile.defaultFirstName);
        expect(remote.upsertUserIds, isEmpty);
      },
    );

    test(
      'favorites remote apply aborted when identity flips mid-fetch',
      () async {
        var currentUserId = 'user-a';
        final store = const FavoritesPreferencesStore();
        final remote = _DelayedFavoritesRemote(
          delay: const Duration(milliseconds: 80),
          records: [
            FavoriteRecord(
              entityType: FavoriteEntityType.place,
              entitySlug: 'place-jardin-majorelle',
              isActive: true,
              updatedAt: DateTime.utc(2026, 8, 1),
            ),
          ],
        );
        final repository = SyncingFavoritesRepository(
          store: store,
          remote: remote,
          env: const AtlasEnv(
            environment: AtlasEnvironment.development,
            supabaseUrl: 'https://example.supabase.co',
            supabaseAnonKey: 'anon-key',
          ),
          userIdProvider: () => currentUserId,
          isSignedInProvider: () => true,
          syncEnabledOverride: true,
          syncTimeout: const Duration(seconds: 2),
        );

        final loadFuture = repository.load();
        await Future<void>.delayed(const Duration(milliseconds: 10));
        currentUserId = 'user-b';
        await LocalUserDataIsolator.clearPersistedUserData();
        await loadFuture;
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(
          repository.isFavorite(
            entityType: FavoriteEntityType.place,
            entitySlug: 'place-jardin-majorelle',
          ),
          isFalse,
        );
        final snapshot = await store.loadSnapshot();
        expect(snapshot.activeRecords, isEmpty);
        expect(remote.upsertUserIds, isEmpty);
      },
    );

    test(
      'prayer prefs remote apply aborted when sign-out mid-sync',
      () async {
        var currentUserId = 'user-a';
        var signedIn = true;
        final prayerStore = const NotificationPreferencesStore();
        await prayerStore.save(PrayerNotificationLeadTime.disabled);

        final remote = _DelayedPrefsRemote(
          delay: const Duration(milliseconds: 80),
          snapshot: UserPreferencesRemoteSnapshot(
            prayerLeadTime: PrayerNotificationLeadTime.tenMinutesBefore,
            atNotificationsEnabled: false,
            explorerCity: 'Casablanca',
            explorerCategory: null,
            explorerFavoritesOnly: false,
            updatedAt: DateTime.utc(2026, 8, 10),
          ),
        );

        final repository = SyncingUserPreferencesRepository(
          prayerStore: prayerStore,
          remote: remote,
          env: const AtlasEnv(
            environment: AtlasEnvironment.development,
            supabaseUrl: 'https://example.supabase.co',
            supabaseAnonKey: 'anon-key',
          ),
          userIdProvider: () => currentUserId,
          isSignedInProvider: () => signedIn,
          syncEnabledOverride: true,
        );

        final syncFuture = repository.sync();
        await Future<void>.delayed(const Duration(milliseconds: 10));
        currentUserId = 'anon-after';
        signedIn = false;
        await LocalUserDataIsolator.clearPersistedUserData();
        await syncFuture;
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(await prayerStore.load(), PrayerNotificationLeadTime.disabled);
        expect(remote.upsertUserIds, isEmpty);
      },
    );

    test(
      'profile save does not upsert into B after A → B mid-push',
      () async {
        var currentUserId = 'user-a';
        final store = const ProfilePreferencesStore();
        final remote = _GateProfileRemote();
        final repository = SyncingProfileRepository(
          store: store,
          env: const AtlasEnv(
            environment: AtlasEnvironment.development,
            supabaseUrl: 'https://example.supabase.co',
            supabaseAnonKey: 'anon-key',
          ),
          remote: remote,
          userIdProvider: () => currentUserId,
          isSignedInProvider: () => true,
          syncEnabledOverride: true,
          syncTimeout: const Duration(seconds: 2),
        );

        await repository.load();
        final saveFuture = repository.save(
          const UserProfile(
            firstName: 'Alice',
            preferredCity: 'Marrakech',
            language: AtlasLanguage.french,
            userType: AtlasUserType.mre,
          ),
        );
        await remote.waitUntilUpsertStarted();
        currentUserId = 'user-b';
        remote.releaseUpsert();
        await saveFuture;

        expect(remote.upsertUserIds, ['user-a']);
        expect(remote.upsertUserIds, isNot(contains('user-b')));
      },
    );
  });

  group('Boundary + stores: no cross-account leakage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'A profile/favorites/prayer cleared then B reload stays empty locally',
      () async {
        const profileStore = ProfilePreferencesStore();
        await profileStore.saveProfile(
          const UserProfile(
            firstName: 'Alice',
            preferredCity: 'Casablanca',
            language: AtlasLanguage.french,
            userType: AtlasUserType.mre,
          ),
          localUpdatedAt: DateTime.utc(2026, 8, 11),
        );
        const favoritesStore = FavoritesPreferencesStore();
        await favoritesStore.saveRecords([
          FavoriteRecord(
            entityType: FavoriteEntityType.place,
            entitySlug: 'place-jardin-majorelle',
            isActive: true,
            updatedAt: DateTime.utc(2026, 8, 11),
          ),
        ]);
        const prayerStore = NotificationPreferencesStore();
        await prayerStore.save(PrayerNotificationLeadTime.tenMinutesBefore);
        const prefsStore = UserPreferencesStore();
        await prefsStore.save(
          UserPreferencesSnapshot(
            prayerLeadTime: PrayerNotificationLeadTime.tenMinutesBefore,
            atNotificationsEnabled: false,
            explorerCity: 'Casablanca',
            explorerCategory: null,
            explorerFavoritesOnly: false,
            localUpdatedAt: DateTime.utc(2026, 8, 11),
            syncPending: true,
          ),
        );

        var session = const AuthSession(
          kind: AuthSessionKind.signedIn,
          userId: 'user-a',
        );
        final reloads = <String>[];

        final controller = AuthSessionBoundaryController(
          sessionProvider: () => session,
          reloadUserScopedData: () async {
            reloads.add(session.userId ?? 'null');
            // Mimic AppShell reload after clear.
            final profile = SyncingProfileRepository(
              store: profileStore,
              userIdProvider: () => session.userId,
              isSignedInProvider: () =>
                  session.kind == AuthSessionKind.signedIn,
            );
            final favorites = SyncingFavoritesRepository(
              store: favoritesStore,
              userIdProvider: () => session.userId,
              isSignedInProvider: () =>
                  session.kind == AuthSessionKind.signedIn,
            );
            await Future.wait([profile.load(), favorites.load()]);
          },
        );

        // Bind A first.
        await controller.handleSessionChanged();

        // Switch A → B while simulating pending local blob from A.
        session = const AuthSession(
          kind: AuthSessionKind.signedIn,
          userId: 'user-b',
        );
        await controller.handleSessionChanged();

        expect(controller.boundUserId, 'user-b');
        expect(reloads, ['user-a', 'user-b']);

        final profileAfter = await profileStore.loadSnapshot();
        expect(profileAfter.profile.firstName, UserProfile.defaultFirstName);
        expect(
          profileAfter.profile.preferredCity,
          UserProfile.defaultPreferredCity,
        );

        final favoritesAfter = await favoritesStore.loadSnapshot();
        expect(favoritesAfter.activeRecords, isEmpty);

        expect(await prayerStore.load(), PrayerNotificationLeadTime.disabled);
        final prefsAfter = await prefsStore.load();
        expect(prefsAfter.prayerLeadTime, PrayerNotificationLeadTime.disabled);
        expect(prefsAfter.syncPending, isFalse);
      },
    );
  });
}

class _DelayedProfileRemote extends SupabaseProfileRepository {
  _DelayedProfileRemote({required this.delay, required this.remote})
    : super(clientProvider: () => throw StateError('no client'));

  final Duration delay;
  final ProfileRemoteSnapshot remote;
  final List<String> upsertUserIds = <String>[];

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
    upsertUserIds.add(userId);
  }
}

class _GateProfileRemote extends SupabaseProfileRepository {
  _GateProfileRemote()
    : super(clientProvider: () => throw StateError('no client'));

  final List<String> upsertUserIds = <String>[];
  Completer<void>? _started;
  Completer<void>? _release;

  Future<void> waitUntilUpsertStarted() async {
    _started ??= Completer<void>();
    await _started!.future;
  }

  void releaseUpsert() {
    _release ??= Completer<void>();
    if (!_release!.isCompleted) _release!.complete();
  }

  @override
  Future<ProfileRemoteSnapshot?> fetch(String userId) async => null;

  @override
  Future<void> upsert({
    required String userId,
    required UserProfile profile,
  }) async {
    upsertUserIds.add(userId);
    _started ??= Completer<void>();
    if (!_started!.isCompleted) _started!.complete();
    _release ??= Completer<void>();
    await _release!.future;
  }
}

class _DelayedFavoritesRemote extends SupabaseFavoritesRepository {
  _DelayedFavoritesRemote({required this.delay, required this.records})
    : super(clientProvider: () => throw StateError('no client'));

  final Duration delay;
  final List<FavoriteRecord> records;
  final List<String> upsertUserIds = <String>[];

  @override
  Future<List<FavoriteRecord>> fetch(String userId) async {
    await Future<void>.delayed(delay);
    return records;
  }

  @override
  Future<void> upsert({
    required String userId,
    required FavoriteRecord record,
  }) async {
    upsertUserIds.add(userId);
  }
}

class _DelayedPrefsRemote extends SupabaseUserPreferencesRepository {
  _DelayedPrefsRemote({required this.delay, required this.snapshot});

  final Duration delay;
  final UserPreferencesRemoteSnapshot snapshot;
  final List<String> upsertUserIds = <String>[];

  @override
  Future<UserPreferencesRemoteSnapshot?> fetch(String userId) async {
    await Future<void>.delayed(delay);
    return snapshot;
  }

  @override
  Future<bool> upsert({
    required String userId,
    required UserPreferencesSnapshot snapshot,
  }) async {
    upsertUserIds.add(userId);
    return true;
  }
}
