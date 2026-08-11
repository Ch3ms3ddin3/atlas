import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/config/atlas_env.dart';
import 'package:atlas/core/notifications/local_notification_service.dart';
import 'package:atlas/core/notifications/notification_preferences_store.dart';
import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/core/notifications/prayer_notification_lead_time.dart';
import 'package:atlas/features/auth/data/local_user_data_isolator.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/home/data/prayer/prayer_notification_coordinator.dart';
import 'package:atlas/features/home/data/prayer/prayer_notification_scheduler.dart';
import 'package:atlas/features/sync/data/supabase_user_preferences_repository.dart';
import 'package:atlas/features/sync/data/syncing_user_preferences_repository.dart';
import 'package:atlas/features/sync/data/user_preferences_store.dart';
import 'package:atlas/features/sync/data/user_preferences_sync_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaceBrowseFilters.resetForTest();
    resetPrayerNotificationBootstrapForTests();
  });

  tearDown(() {
    PlaceBrowseFilters.resetForTest();
    resetPrayerNotificationBootstrapForTests();
  });

  group('prayer preference change marks cloud-pending', () {
    test('setLeadTime disabled stamps pending + localUpdatedAt', () async {
      final notifications = _RecordingNotificationService();
      final coordinator = PrayerNotificationCoordinator(
        notificationService: notifications,
      );

      final ok = await coordinator.setLeadTime(
        PrayerNotificationLeadTime.disabled,
      );
      expect(ok, isTrue);

      final prefs = await const UserPreferencesStore().load();
      expect(prefs.prayerLeadTime, PrayerNotificationLeadTime.disabled);
      expect(prefs.syncPending, isTrue);
      expect(prefs.localUpdatedAt, isNotNull);
      expect(notifications.cancelPrayerCount, greaterThan(0));

      final prayerOnly = await const NotificationPreferencesStore().load();
      expect(prayerOnly, PrayerNotificationLeadTime.disabled);
    });

    test('setLeadTime invokes cloud persist hook when bound', () async {
      var persistCalls = 0;
      final coordinator = PrayerNotificationCoordinator(
        notificationService: _RecordingNotificationService(),
      );
      coordinator.bindCloudPersist(() async {
        persistCalls += 1;
      });

      await coordinator.setLeadTime(PrayerNotificationLeadTime.disabled);
      expect(persistCalls, 1);
    });
  });

  group('stale remote must not overwrite pending local prayer', () {
    test('syncPending local prayer wins over newer remote', () {
      final local = UserPreferencesSnapshot(
        prayerLeadTime: PrayerNotificationLeadTime.fiveMinutesBefore,
        atNotificationsEnabled: false,
        explorerCity: 'Marrakech',
        explorerCategory: null,
        explorerFavoritesOnly: false,
        localUpdatedAt: DateTime.utc(2026, 8, 1),
        syncPending: true,
      );
      final remote = UserPreferencesRemoteSnapshot(
        prayerLeadTime: PrayerNotificationLeadTime.disabled,
        atNotificationsEnabled: false,
        explorerCity: 'Marrakech',
        explorerCategory: null,
        explorerFavoritesOnly: false,
        updatedAt: DateTime.utc(2026, 8, 11),
      );

      final merge = UserPreferencesSyncCoordinator.merge(
        local: local,
        remote: remote,
      );

      expect(merge.shouldPush, isTrue);
      expect(merge.changed, isFalse);
      expect(
        merge.snapshot.prayerLeadTime,
        PrayerNotificationLeadTime.fiveMinutesBefore,
      );
    });

    test(
      'after setLeadTime, merge keeps local against older/stale remote',
      () async {
        final coordinator = PrayerNotificationCoordinator(
          notificationService: _RecordingNotificationService(),
        );
        await coordinator.setLeadTime(
          PrayerNotificationLeadTime.tenMinutesBefore,
        );

        // Simulate permission path on non-web: tenMinutesBefore needs permission.
        // On VM tests kIsWeb is false; RecordingNotificationService grants true.
        final local = await const UserPreferencesStore().load();
        expect(local.syncPending, isTrue);
        expect(
          local.prayerLeadTime,
          PrayerNotificationLeadTime.tenMinutesBefore,
        );

        final merge = UserPreferencesSyncCoordinator.merge(
          local: local,
          remote: UserPreferencesRemoteSnapshot(
            prayerLeadTime: PrayerNotificationLeadTime.disabled,
            atNotificationsEnabled: false,
            explorerCity: '',
            explorerCategory: null,
            explorerFavoritesOnly: false,
            updatedAt: DateTime.utc(2099, 1, 1),
          ),
        );

        expect(
          merge.snapshot.prayerLeadTime,
          PrayerNotificationLeadTime.tenMinutesBefore,
        );
        expect(merge.shouldPush, isTrue);
      },
    );
  });

  group('persistence across restart', () {
    test('lead time survives store reload', () async {
      final coordinator = PrayerNotificationCoordinator(
        notificationService: _RecordingNotificationService(),
      );
      await coordinator.setLeadTime(
        PrayerNotificationLeadTime.fiveMinutesBefore,
      );

      final reloaded = PrayerNotificationCoordinator(
        notificationService: _RecordingNotificationService(),
      );
      expect(
        await reloaded.currentLeadTime(),
        PrayerNotificationLeadTime.fiveMinutesBefore,
      );

      final snapshot = await const UserPreferencesStore().load();
      expect(
        snapshot.prayerLeadTime,
        PrayerNotificationLeadTime.fiveMinutesBefore,
      );
      expect(snapshot.syncPending, isTrue);
    });
  });

  group('sync after reconnect pushes pending prayer', () {
    test('offline change then sync upserts local prayer lead time', () async {
      final remote = _CapturingPrefsRemote();
      final repository = SyncingUserPreferencesRepository(
        remote: remote,
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: 'https://example.supabase.co',
          supabaseAnonKey: 'anon-key',
        ),
        userIdProvider: () => 'user-1',
        isSignedInProvider: () => true,
        syncEnabledOverride: true,
      );

      final coordinator = PrayerNotificationCoordinator(
        notificationService: _RecordingNotificationService(),
      );
      coordinator.bindCloudPersist(
        () => repository.persistFromUi(awaitSync: true),
      );

      await coordinator.setLeadTime(
        PrayerNotificationLeadTime.fiveMinutesBefore,
      );

      expect(remote.upsertCount, greaterThan(0));
      expect(
        remote.lastUpserted?.prayerLeadTime,
        PrayerNotificationLeadTime.fiveMinutesBefore,
      );

      final stored = await const UserPreferencesStore().load();
      expect(stored.syncPending, isFalse);
    });
  });

  group('sign-in restores cloud prayer preference', () {
    test(
      'awaited persist then clear then signed-in sync restores lead time',
      () async {
        final remote = _CapturingPrefsRemote();
        var signedIn = true;
        final repository = SyncingUserPreferencesRepository(
          remote: remote,
          env: const AtlasEnv(
            environment: AtlasEnvironment.development,
            supabaseUrl: 'https://example.supabase.co',
            supabaseAnonKey: 'anon-key',
          ),
          userIdProvider: () => 'user-1',
          isSignedInProvider: () => signedIn,
          syncEnabledOverride: true,
        );

        final notifications = _RecordingNotificationService();
        ensurePrayerNotificationCoordinatorForTests(
          notificationService: notifications,
        );
        prayerNotificationCoordinator.bindCloudPersist(
          () => repository.persistFromUi(awaitSync: true),
        );

        await prayerNotificationCoordinator.setLeadTime(
          PrayerNotificationLeadTime.tenMinutesBefore,
        );
        expect(
          remote.lastUpserted?.prayerLeadTime,
          PrayerNotificationLeadTime.tenMinutesBefore,
        );

        // Sign-out: clear local personal data (P7). Cloud row stays.
        signedIn = false;
        await LocalUserDataIsolator.clearPersistedUserData();
        expect(
          await const NotificationPreferencesStore().load(),
          PrayerNotificationLeadTime.disabled,
        );

        // Sign-in same account: pull remote and restore.
        signedIn = true;
        remote.seedFetch = UserPreferencesRemoteSnapshot(
          prayerLeadTime: PrayerNotificationLeadTime.tenMinutesBefore,
          atNotificationsEnabled: false,
          explorerCity: '',
          explorerCategory: null,
          explorerFavoritesOnly: false,
          updatedAt: DateTime.utc(2026, 8, 11, 20),
        );
        await repository.sync();
        await prayerNotificationCoordinator.sync(force: true);

        expect(
          await const NotificationPreferencesStore().load(),
          PrayerNotificationLeadTime.tenMinutesBefore,
        );
        expect(
          await prayerNotificationCoordinator.currentLeadTime(),
          PrayerNotificationLeadTime.tenMinutesBefore,
        );
      },
    );
  });

  group('remote apply reschedules OS preference', () {
    test('applying remote disabled cancels prayer notifications', () async {
      final notifications = _RecordingNotificationService();
      ensurePrayerNotificationCoordinatorForTests(
        notificationService: notifications,
      );

      // Seed an enabled preference first.
      await const NotificationPreferencesStore().save(
        PrayerNotificationLeadTime.atPrayerTime,
      );
      await const UserPreferencesStore().save(
        UserPreferencesSnapshot(
          prayerLeadTime: PrayerNotificationLeadTime.atPrayerTime,
          atNotificationsEnabled: false,
          explorerCity: '',
          explorerCategory: null,
          explorerFavoritesOnly: false,
          localUpdatedAt: DateTime.utc(2026, 7, 1),
        ),
      );

      final remote = _StubPrefsRemote(
        UserPreferencesRemoteSnapshot(
          prayerLeadTime: PrayerNotificationLeadTime.disabled,
          atNotificationsEnabled: false,
          explorerCity: '',
          explorerCategory: null,
          explorerFavoritesOnly: false,
          updatedAt: DateTime.utc(2026, 8, 11),
        ),
      );

      final repository = SyncingUserPreferencesRepository(
        remote: remote,
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: 'https://example.supabase.co',
          supabaseAnonKey: 'anon-key',
        ),
        userIdProvider: () => 'user-1',
        isSignedInProvider: () => true,
        syncEnabledOverride: true,
      );

      final beforeCancels = notifications.cancelPrayerCount;
      await repository.sync();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        await const NotificationPreferencesStore().load(),
        PrayerNotificationLeadTime.disabled,
      );
      expect(
        notifications.cancelPrayerCount,
        greaterThan(beforeCancels),
      );
    });
  });

  group('sign-out isolation clears prayer preference', () {
    test('clearPersistedUserData resets prayer + pending metadata', () async {
      final notifications = _RecordingNotificationService();
      ensurePrayerNotificationCoordinatorForTests(
        notificationService: notifications,
      );

      await prayerNotificationCoordinator.setLeadTime(
        PrayerNotificationLeadTime.fiveMinutesBefore,
      );

      await LocalUserDataIsolator.clearPersistedUserData();
      await prayerNotificationCoordinator.sync(force: true);

      expect(
        await const NotificationPreferencesStore().load(),
        PrayerNotificationLeadTime.disabled,
      );
      final prefs = await const UserPreferencesStore().load();
      expect(prefs.prayerLeadTime, PrayerNotificationLeadTime.disabled);
      expect(prefs.syncPending, isFalse);
      expect(prefs.localUpdatedAt, isNull);
      expect(notifications.cancelPrayerCount, greaterThan(0));
    });
  });

  group('sign-in restoration via merge', () {
    test('no local edits: remote prayer applies', () {
      final local = UserPreferencesSnapshot(
        prayerLeadTime: PrayerNotificationLeadTime.disabled,
        atNotificationsEnabled: false,
        explorerCity: '',
        explorerCategory: null,
        explorerFavoritesOnly: false,
      );
      final remote = UserPreferencesRemoteSnapshot(
        prayerLeadTime: PrayerNotificationLeadTime.atPrayerTime,
        atNotificationsEnabled: false,
        explorerCity: '',
        explorerCategory: null,
        explorerFavoritesOnly: false,
        updatedAt: DateTime.utc(2026, 8, 11),
      );

      final merge = UserPreferencesSyncCoordinator.merge(
        local: local,
        remote: remote,
      );

      expect(merge.changed, isTrue);
      expect(
        merge.snapshot.prayerLeadTime,
        PrayerNotificationLeadTime.atPrayerTime,
      );
      expect(merge.shouldPush, isFalse);
    });
  });

  group('disabled preference cancels schedules', () {
    test('sync with disabled cancels and does not schedule', () async {
      final notifications = _RecordingNotificationService();
      final coordinator = PrayerNotificationCoordinator(
        notificationService: notifications,
      );
      await const NotificationPreferencesStore().save(
        PrayerNotificationLeadTime.disabled,
      );

      await coordinator.sync(force: true);

      expect(notifications.cancelPrayerCount, 1);
      expect(notifications.scheduleCount, 0);
    });
  });
}

class _RecordingNotificationService extends LocalNotificationService {
  int cancelPrayerCount = 0;
  int scheduleCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> requestExactAlarmsIfNeeded() async {}

  @override
  Future<void> cancelPrayerNotifications() async {
    cancelPrayerCount += 1;
  }

  @override
  Future<void> schedule(ScheduledPrayerNotification notification) async {
    scheduleCount += 1;
  }
}

class _CapturingPrefsRemote extends SupabaseUserPreferencesRepository {
  int upsertCount = 0;
  UserPreferencesSnapshot? lastUpserted;
  UserPreferencesRemoteSnapshot? seedFetch;

  @override
  Future<UserPreferencesRemoteSnapshot?> fetch(String userId) async {
    if (seedFetch != null) return seedFetch;
    if (lastUpserted == null) return null;
    return UserPreferencesRemoteSnapshot(
      prayerLeadTime: lastUpserted!.prayerLeadTime,
      atNotificationsEnabled: lastUpserted!.atNotificationsEnabled,
      explorerCity: lastUpserted!.explorerCity,
      explorerCategory: lastUpserted!.explorerCategory,
      explorerFavoritesOnly: lastUpserted!.explorerFavoritesOnly,
      updatedAt:
          lastUpserted!.localUpdatedAt ?? DateTime.now().toUtc(),
    );
  }

  @override
  Future<bool> upsert({
    required String userId,
    required UserPreferencesSnapshot snapshot,
  }) async {
    upsertCount += 1;
    lastUpserted = snapshot;
    return true;
  }
}

class _StubPrefsRemote extends SupabaseUserPreferencesRepository {
  _StubPrefsRemote(this.remote);

  final UserPreferencesRemoteSnapshot remote;

  @override
  Future<UserPreferencesRemoteSnapshot?> fetch(String userId) async => remote;

  @override
  Future<bool> upsert({
    required String userId,
    required UserPreferencesSnapshot snapshot,
  }) async =>
      true;
}
