import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/notifications/prayer_notification_lead_time.dart';
import 'package:atlas/features/admission_temporaire/data/at_preferences_store.dart';
import 'package:atlas/features/admission_temporaire/data/at_sync_coordinator.dart';
import 'package:atlas/features/admission_temporaire/domain/models/at_vehicle.dart';
import 'package:atlas/features/explorer/domain/models/place_models.dart';
import 'package:atlas/features/auth/data/supabase_auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/sync/data/user_preferences_store.dart';
import 'package:atlas/features/sync/data/user_preferences_sync_coordinator.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserPreferencesSyncCoordinator', () {
    test('sans remote conserve le local et pousse si pending', () {
      final local = UserPreferencesSnapshot(
        prayerLeadTime: PrayerNotificationLeadTime.atPrayerTime,
        atNotificationsEnabled: true,
        explorerCity: 'Rabat',
        explorerCategory: PlaceCategory.monument,
        explorerFavoritesOnly: false,
        localUpdatedAt: DateTime.utc(2026, 7, 1),
        syncPending: true,
      );
      final merge = UserPreferencesSyncCoordinator.merge(
        local: local,
        remote: null,
      );
      expect(merge.shouldPush, isTrue);
      expect(merge.changed, isFalse);
      expect(merge.snapshot.explorerCity, 'Rabat');
    });

    test('remote plus récent gagne sauf syncPending local', () {
      final local = UserPreferencesSnapshot(
        prayerLeadTime: PrayerNotificationLeadTime.disabled,
        atNotificationsEnabled: false,
        explorerCity: 'Fès',
        explorerCategory: null,
        explorerFavoritesOnly: true,
        localUpdatedAt: DateTime.utc(2026, 7, 1),
        syncPending: true,
      );
      final remote = UserPreferencesRemoteSnapshot(
        prayerLeadTime: PrayerNotificationLeadTime.fiveMinutesBefore,
        atNotificationsEnabled: true,
        explorerCity: 'Tanger',
        explorerCategory: PlaceCategory.jardin,
        explorerFavoritesOnly: false,
        updatedAt: DateTime.utc(2026, 7, 10),
      );
      final merge = UserPreferencesSyncCoordinator.merge(
        local: local,
        remote: remote,
      );
      expect(merge.snapshot.explorerCity, 'Fès');
      expect(merge.shouldPush, isTrue);
    });
  });

  group('AtSyncCoordinator', () {
    test('préfère le local quand syncPending', () {
      final localVehicle = AtVehicle(
        id: 'v1',
        label: 'Local',
        plate: 'AA-111',
        countryCode: 'FR',
        countryLabel: 'France',
        type: AtVehicleType.car,
        entryDate: DateTime(2026, 1, 1),
        expiryDate: DateTime(2026, 4, 1),
        durationDays: 90,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      );
      final remoteVehicle = localVehicle.copyWith(
        label: 'Remote',
        updatedAt: DateTime.utc(2026, 7, 1),
      );
      final merged = AtSyncCoordinator.merge(
        local: AtLocalSnapshot(
          vehicles: [localVehicle],
          notificationsEnabled: false,
          notificationPromptShown: false,
          syncPending: true,
        ),
        remote: [remoteVehicle],
      );
      expect(merged.vehicles.single.label, 'Local');
    });
  });

  group('SupabaseAuthRepository', () {
    test('sans backend : OAuth et reset renvoient backendUnavailable', () async {
      final repository = SupabaseAuthRepository();
      await repository.load();
      expect(repository.session.kind, AuthSessionKind.unavailable);
      expect((await repository.signInWithApple()).backendUnavailable, isTrue);
      expect((await repository.signInWithGoogle()).backendUnavailable, isTrue);
      expect(
        (await repository.resetPassword(email: 'a@b.c')).backendUnavailable,
        isTrue,
      );
      expect((await repository.deleteAccount()).backendUnavailable, isTrue);
    });
  });
}
