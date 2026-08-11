import 'package:atlas/core/notifications/prayer_notification_bootstrap.dart';
import 'package:atlas/features/home/data/prayer/prayer_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    resetPrayerNotificationBootstrapForTests();
    PrayerRepository.resetForTest();
  });

  test(
    'prayerNotificationCoordinator is readable before bootstrapPrayerNotifications',
    () {
      resetPrayerNotificationBootstrapForTests();
      PrayerRepository.resetForTest();

      // Simulates Profile IndexedStack build before deferred main bootstrap.
      expect(() => prayerNotificationCoordinator, returnsNormally);
      expect(prayerNotificationCoordinator, isNotNull);
      expect(
        identical(
          prayerNotificationCoordinator,
          prayerNotificationCoordinator,
        ),
        isTrue,
      );
    },
  );

  test('ensurePrayerNotificationCoordinatorForTests replaces the instance', () {
    resetPrayerNotificationBootstrapForTests();
    PrayerRepository.resetForTest();
    final first = prayerNotificationCoordinator;

    final custom = PrayerRepository();
    ensurePrayerNotificationCoordinatorForTests(prayerRepository: custom);

    expect(identical(first, prayerNotificationCoordinator), isFalse);
    expect(identical(PrayerRepository.instance, custom), isTrue);
  });
}
