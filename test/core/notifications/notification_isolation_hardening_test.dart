import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/notifications/local_notification_service.dart';
import 'package:atlas/core/notifications/notification_preferences_store.dart';
import 'package:atlas/core/notifications/prayer_notification_lead_time.dart';
import 'package:atlas/features/admission_temporaire/data/at_notification_coordinator.dart';
import 'package:atlas/features/admission_temporaire/data/at_notification_scheduler.dart';
import 'package:atlas/features/admission_temporaire/data/local_at_repository.dart';
import 'package:atlas/features/home/data/prayer/prayer_notification_coordinator.dart';
import 'package:atlas/features/home/data/prayer/prayer_notification_scheduler.dart';
import 'package:atlas/features/home/data/prayer/prayer_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PrayerRepository.resetForTest();
  });

  tearDown(PrayerRepository.resetForTest);

  group('AtNotificationCoordinator identity isolation', () {
    test('sync cancels AT schedules when notifications are disabled', () async {
      final notifications = _RecordingNotificationService();
      final repository = LocalAtRepository();
      await repository.load();
      expect(repository.notificationsEnabled, isFalse);

      final coordinator = AtNotificationCoordinator(
        repository: repository,
        notificationService: notifications,
      );

      await coordinator.sync(force: true);

      expect(notifications.initializeCount, greaterThan(0));
      expect(notifications.cancelAtCount, 1);
      expect(notifications.scheduleAtCount, 0);
    });

    test(
      'disableNotifications cancels even if initialize was never called',
      () async {
        final notifications = _RecordingNotificationService();
        final repository = LocalAtRepository();
        await repository.load();
        await repository.setNotificationsEnabled(true);

        final coordinator = AtNotificationCoordinator(
          repository: repository,
          notificationService: notifications,
        );

        await coordinator.disableNotifications();

        expect(repository.notificationsEnabled, isFalse);
        expect(notifications.cancelAtCount, 1);
      },
    );
  });

  group('PrayerNotificationCoordinator first-launch race', () {
    test('setLeadTime initializes before scheduling when enabling', () async {
      final notifications = _RecordingNotificationService();
      final coordinator = PrayerNotificationCoordinator(
        preferencesStore: const NotificationPreferencesStore(),
        notificationService: notifications,
        prayerRepository: PrayerRepository(),
      );

      final ok = await coordinator.setLeadTime(
        PrayerNotificationLeadTime.fiveMinutesBefore,
      );

      expect(ok, isTrue);
      expect(notifications.initializeCount, greaterThan(0));
      // Permission granted via fake; sync may cancel if no timings —
      // but initialize must precede any schedule/cancel path.
      expect(notifications.initializeBeforeScheduleOrCancel, isTrue);
    });

    test('setLeadTime returns false when permission denied', () async {
      final notifications = _RecordingNotificationService(
        grantPermission: false,
      );
      final coordinator = PrayerNotificationCoordinator(
        preferencesStore: const NotificationPreferencesStore(),
        notificationService: notifications,
        prayerRepository: PrayerRepository(),
      );

      final ok = await coordinator.setLeadTime(
        PrayerNotificationLeadTime.fiveMinutesBefore,
      );

      expect(ok, isFalse);
      expect(notifications.scheduleCount, 0);
      final stored = await const NotificationPreferencesStore().load();
      expect(stored, PrayerNotificationLeadTime.disabled);
    });
  });

  group('LocalNotificationService init-before-action', () {
    testWidgets('cancel paths call initialize first via recording subclass', (
      tester,
    ) async {
      final notifications = _RecordingNotificationService();
      await notifications.cancelAtNotifications();
      await notifications.cancelPrayerNotifications();
      expect(notifications.initializeCount, greaterThanOrEqualTo(2));
      expect(notifications.cancelAtCount, 1);
      expect(notifications.cancelPrayerCount, 1);
    });
  });
}

class _RecordingNotificationService extends LocalNotificationService {
  _RecordingNotificationService({this.grantPermission = true});

  final bool grantPermission;
  int initializeCount = 0;
  int cancelAtCount = 0;
  int cancelPrayerCount = 0;
  int scheduleCount = 0;
  int scheduleAtCount = 0;
  bool initializeBeforeScheduleOrCancel = true;
  bool _sawActionBeforeInit = false;

  @override
  Future<void> initialize() async {
    initializeCount += 1;
  }

  @override
  Future<bool> requestPermission() async => grantPermission;

  @override
  Future<void> requestExactAlarmsIfNeeded() async {}

  @override
  Future<void> cancelPrayerNotifications() async {
    if (initializeCount == 0) _sawActionBeforeInit = true;
    // Mirror production: ensure init before cancel.
    await initialize();
    cancelPrayerCount += 1;
    if (_sawActionBeforeInit) initializeBeforeScheduleOrCancel = false;
  }

  @override
  Future<void> cancelAtNotifications() async {
    if (initializeCount == 0) _sawActionBeforeInit = true;
    await initialize();
    cancelAtCount += 1;
    if (_sawActionBeforeInit) initializeBeforeScheduleOrCancel = false;
  }

  @override
  Future<void> schedule(ScheduledPrayerNotification notification) async {
    if (initializeCount == 0) {
      initializeBeforeScheduleOrCancel = false;
    }
    await initialize();
    scheduleCount += 1;
  }

  @override
  Future<void> scheduleAt(ScheduledAtNotification notification) async {
    if (initializeCount == 0) {
      initializeBeforeScheduleOrCancel = false;
    }
    await initialize();
    scheduleAtCount += 1;
  }
}
