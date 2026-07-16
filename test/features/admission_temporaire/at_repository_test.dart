import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/features/admission_temporaire/data/at_calculator.dart';
import 'package:atlas/features/admission_temporaire/data/at_notification_scheduler.dart';
import 'package:atlas/features/admission_temporaire/data/at_preferences_store.dart';
import 'package:atlas/features/admission_temporaire/data/local_at_repository.dart';
import 'package:atlas/features/admission_temporaire/domain/models/at_vehicle.dart';

AtVehicle _vehicle({
  required String id,
  required DateTime entry,
  required int durationDays,
  String label = 'Golf',
  String plate = 'AB-123-CD',
  int slot = 0,
}) {
  final expiry = AtCalculator.expiryFromEntry(
    entryDate: entry,
    durationDays: durationDays,
  );
  final now = DateTime.utc(2026, 7, 16);
  return AtVehicle(
    id: id,
    label: label,
    plate: plate,
    countryCode: 'FR',
    countryLabel: 'France',
    type: AtVehicleType.car,
    entryDate: entry,
    expiryDate: expiry,
    durationDays: durationDays,
    createdAt: now,
    updatedAt: now,
    notificationSlot: slot,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AtCalculator', () {
    test('calcule expiration, jours restants et statuts', () {
      final entry = DateTime(2026, 1, 1);
      final expiry = AtCalculator.expiryFromEntry(
        entryDate: entry,
        durationDays: 180,
      );
      expect(expiry, DateTime(2026, 6, 30));

      expect(
        AtCalculator.remainingDays(
          expiryDate: DateTime(2026, 7, 20),
          now: DateTime(2026, 7, 10),
        ),
        10,
      );
      expect(
        AtCalculator.status(
          expiryDate: DateTime(2026, 8, 20),
          now: DateTime(2026, 7, 10),
        ),
        AtUrgencyStatus.ok,
      );
      expect(
        AtCalculator.status(
          expiryDate: DateTime(2026, 7, 25),
          now: DateTime(2026, 7, 10),
        ),
        AtUrgencyStatus.warning,
      );
      expect(
        AtCalculator.status(
          expiryDate: DateTime(2026, 7, 15),
          now: DateTime(2026, 7, 10),
        ),
        AtUrgencyStatus.critical,
      );
      expect(
        AtCalculator.status(
          expiryDate: DateTime(2026, 7, 1),
          now: DateTime(2026, 7, 10),
        ),
        AtUrgencyStatus.expired,
      );
    });

    test('choisit le véhicule le plus urgent', () {
      final urgent = _vehicle(
        id: 'a',
        entry: DateTime(2026, 6, 1),
        durationDays: 45,
        label: 'Urgent',
      );
      final later = _vehicle(
        id: 'b',
        entry: DateTime(2026, 1, 1),
        durationDays: 365,
        label: 'Plus tard',
        slot: 1,
      );
      final pick = AtCalculator.mostUrgent(
        [later, urgent],
        now: DateTime(2026, 7, 10),
      );
      expect(pick?.id, 'a');
    });
  });

  group('LocalAtRepository', () {
    test('persiste plusieurs véhicules et soft-delete', () async {
      final repository = LocalAtRepository();
      await repository.load();

      final first = _vehicle(
        id: 'v1',
        entry: DateTime(2026, 4, 1),
        durationDays: 180,
      );
      final second = _vehicle(
        id: 'v2',
        entry: DateTime(2026, 5, 1),
        durationDays: 90,
        label: 'Van',
        plate: 'EF-456-GH',
        slot: 1,
      );

      expect(await repository.addVehicle(first), isTrue);
      expect(await repository.addVehicle(second), isTrue);
      expect(repository.activeVehicles, hasLength(2));

      expect(await repository.deleteVehicle('v1'), isTrue);
      expect(repository.activeVehicles, hasLength(1));
      expect(repository.activeVehicles.first.id, 'v2');
      expect(repository.vehicles.where((v) => v.id == 'v1').first.isActive, isFalse);

      final reloaded = LocalAtRepository();
      await reloaded.load();
      expect(reloaded.activeVehicles, hasLength(1));
      expect(reloaded.activeVehicles.first.plate, 'EF-456-GH');
    });

    test('notifications désactivées par défaut', () async {
      final repository = LocalAtRepository();
      await repository.load();
      expect(repository.notificationsEnabled, isFalse);
      expect(repository.notificationPromptShown, isFalse);

      await repository.markNotificationPromptShown();
      expect(repository.notificationPromptShown, isTrue);
    });
  });

  group('AtNotificationScheduler', () {
    test('planifie les seuils futurs et ignore le passé', () {
      final vehicle = _vehicle(
        id: 'v1',
        entry: DateTime(2026, 6, 1),
        durationDays: 40,
      );
      // expiry = 11 juillet 2026 ; now = 5 juillet → J-7 déjà passé
      final scheduled = const AtNotificationScheduler().build(
        vehicles: [vehicle],
        notificationsEnabled: true,
        now: DateTime(2026, 7, 5, 10),
      );

      final days = scheduled.map((n) => n.daysBeforeExpiry).toSet();
      expect(days.contains(30), isFalse);
      expect(days.contains(15), isFalse);
      expect(days.contains(7), isFalse);
      expect(days.contains(3), isTrue);
      expect(days.contains(1), isTrue);
      expect(days.contains(0), isTrue);
    });

    test('ne planifie rien si désactivé', () {
      final vehicle = _vehicle(
        id: 'v1',
        entry: DateTime(2026, 1, 1),
        durationDays: 180,
      );
      final scheduled = const AtNotificationScheduler().build(
        vehicles: [vehicle],
        notificationsEnabled: false,
        now: DateTime(2026, 2, 1),
      );
      expect(scheduled, isEmpty);
    });
  });

  group('AtPreferencesStore', () {
    test('round-trip JSON', () async {
      const store = AtPreferencesStore();
      final vehicle = _vehicle(
        id: 'v1',
        entry: DateTime(2026, 3, 1),
        durationDays: 90,
      );
      await store.saveVehicles([vehicle]);
      await store.setNotificationsEnabled(true);
      await store.setNotificationPromptShown(true);

      final snapshot = await store.loadSnapshot();
      expect(snapshot.activeVehicles, hasLength(1));
      expect(snapshot.activeVehicles.first.label, 'Golf');
      expect(snapshot.notificationsEnabled, isTrue);
      expect(snapshot.notificationPromptShown, isTrue);
    });
  });
}
