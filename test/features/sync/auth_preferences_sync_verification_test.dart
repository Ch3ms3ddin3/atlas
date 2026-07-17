import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/notifications/prayer_notification_lead_time.dart';
import 'package:atlas/features/auth/data/supabase_auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/explorer/domain/models/place_models.dart';
import 'package:atlas/features/explorer/domain/place_browse_filters.dart';
import 'package:atlas/features/profile/data/profile_record_mapper.dart';
import 'package:atlas/features/profile/domain/models/user_profile.dart';
import 'package:atlas/features/sync/data/syncing_user_preferences_repository.dart';
import 'package:atlas/features/sync/data/user_preferences_store.dart';
import 'package:atlas/features/sync/data/user_preferences_sync_coordinator.dart';
import 'package:atlas/features/sync/domain/cloud_sync_status.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaceBrowseFilters.resetForTest();
  });

  tearDown(PlaceBrowseFilters.resetForTest);

  group('anonymous / offline mode', () {
    test('auth sans backend reste unavailable et utilisable', () async {
      final auth = SupabaseAuthRepository();
      await auth.load();
      expect(auth.session.kind, AuthSessionKind.unavailable);
      expect(auth.session.isCloudAvailable, isFalse);
    });

    test('préférences restent locales sans écrasement distant', () async {
      const store = UserPreferencesStore();
      final local = UserPreferencesSnapshot(
        prayerLeadTime: PrayerNotificationLeadTime.atPrayerTime,
        atNotificationsEnabled: false,
        explorerCity: 'Casablanca',
        explorerCategory: PlaceCategory.monument,
        explorerFavoritesOnly: true,
        localUpdatedAt: DateTime.utc(2026, 7, 15),
        syncPending: false,
      );
      await store.save(local);
      store.applyExplorerFilters(local);

      expect(PlaceBrowseFilters.instance.cityName, 'Casablanca');
      expect(PlaceBrowseFilters.instance.favoritesOnly, isTrue);

      final merge = UserPreferencesSyncCoordinator.merge(
        local: local,
        remote: null,
      );
      expect(merge.changed, isFalse);
      expect(merge.snapshot.explorerCity, 'Casablanca');
    });

    test('SyncingUserPreferencesRepository marque offline sans backend',
        () async {
      final repository = SyncingUserPreferencesRepository();
      await repository.load();
      expect(repository.isLoaded, isTrue);
      expect(
        repository.status.phase,
        anyOf(CloudSyncPhase.offline, CloudSyncPhase.idle),
      );
    });
  });

  group('authenticated preference sync after login', () {
    test('après login : remote plus récent fusionne dans le local', () {
      final local = UserPreferencesSnapshot(
        prayerLeadTime: PrayerNotificationLeadTime.disabled,
        atNotificationsEnabled: false,
        explorerCity: 'Marrakech',
        explorerCategory: null,
        explorerFavoritesOnly: false,
        localUpdatedAt: DateTime.utc(2026, 7, 1),
        syncPending: false,
      );
      final remote = UserPreferencesRemoteSnapshot(
        prayerLeadTime: PrayerNotificationLeadTime.tenMinutesBefore,
        atNotificationsEnabled: true,
        explorerCity: 'Rabat',
        explorerCategory: PlaceCategory.jardin,
        explorerFavoritesOnly: true,
        updatedAt: DateTime.utc(2026, 7, 16),
      );

      final merge = UserPreferencesSyncCoordinator.merge(
        local: local,
        remote: remote,
      );

      expect(merge.changed, isTrue);
      expect(merge.shouldPush, isFalse);
      expect(merge.snapshot.explorerCity, 'Rabat');
      expect(merge.snapshot.prayerLeadTime,
          PrayerNotificationLeadTime.tenMinutesBefore);
      expect(merge.snapshot.atNotificationsEnabled, isTrue);
    });

    test('après login : pending local n\'est pas écrasé silencieusement', () {
      final local = UserPreferencesSnapshot(
        prayerLeadTime: PrayerNotificationLeadTime.atPrayerTime,
        atNotificationsEnabled: true,
        explorerCity: 'Agadir',
        explorerCategory: PlaceCategory.monument,
        explorerFavoritesOnly: false,
        localUpdatedAt: DateTime.utc(2026, 7, 1),
        syncPending: true,
      );
      final remote = UserPreferencesRemoteSnapshot(
        prayerLeadTime: PrayerNotificationLeadTime.disabled,
        atNotificationsEnabled: false,
        explorerCity: 'Tanger',
        explorerCategory: null,
        explorerFavoritesOnly: true,
        updatedAt: DateTime.utc(2026, 7, 20),
      );

      final merge = UserPreferencesSyncCoordinator.merge(
        local: local,
        remote: remote,
      );

      expect(merge.snapshot.explorerCity, 'Agadir');
      expect(merge.shouldPush, isTrue);
    });
  });

  group('extended profile model', () {
    test('types étendus + visitor legacy + avatar URL', () {
      expect(
        AtlasUserTypeLabels.fromStorage('visitor'),
        AtlasUserType.tourist,
      );
      expect(
        AtlasUserTypeLabels.fromStorage('expatriate'),
        AtlasUserType.expatriate,
      );

      const profile = UserProfile(
        firstName: 'Salma',
        preferredCity: 'Fès',
        language: AtlasLanguage.french,
        userType: AtlasUserType.student,
        displayName: 'Salma Atlas',
        avatarUrl: 'https://example.com/a.png',
      );
      expect(profile.resolvedDisplayName, 'Salma Atlas');

      final row = ProfileRecordMapper.toRow(userId: 'u1', profile: profile);
      expect(row['user_type'], 'student');
      expect(row['display_name'], 'Salma Atlas');
      expect(row['avatar_url'], 'https://example.com/a.png');

      final remote = ProfileRecordMapper.fromRow({
        ...row,
        'updated_at': '2026-07-17T10:00:00.000Z',
      });
      expect(remote.profile.avatarUrl, 'https://example.com/a.png');
      expect(remote.profile.userType, AtlasUserType.student);
    });
  });
}
