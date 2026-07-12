import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/notifications/prayer_notification_lead_time.dart';
import 'package:atlas/features/home/data/prayer/prayer_notification_scheduler.dart';

void main() {
  group('PrayerNotificationScheduler', () {
    const scheduler = PrayerNotificationScheduler();

    const todayTimings = {
      'Fajr': '05:08',
      'Dhuhr': '13:22',
      'Asr': '16:58',
      'Maghrib': '20:11',
      'Isha': '21:28',
    };

    const tomorrowTimings = {
      'Fajr': '05:09',
      'Dhuhr': '13:23',
      'Asr': '16:59',
      'Maghrib': '20:10',
      'Isha': '21:27',
    };

    test('renvoie une liste vide si les rappels sont désactivés', () {
      final notifications = scheduler.build(
        todayTimings: todayTimings,
        tomorrowTimings: tomorrowTimings,
        leadTime: PrayerNotificationLeadTime.disabled,
        now: DateTime(2026, 7, 12, 14, 0),
      );

      expect(notifications, isEmpty);
    });

    test('ignore les prières déjà passées aujourd\'hui', () {
      final notifications = scheduler.build(
        todayTimings: todayTimings,
        tomorrowTimings: tomorrowTimings,
        leadTime: PrayerNotificationLeadTime.atPrayerTime,
        now: DateTime(2026, 7, 12, 17, 0),
      );

      final todayNames = notifications
          .where((item) => item.id <= 5)
          .map((item) => item.prayerName)
          .toList();

      expect(todayNames, ['Maghrib', 'Isha']);
      expect(
        notifications.every((item) => item.scheduledAt.isAfter(
              DateTime(2026, 7, 12, 17, 0),
            )),
        isTrue,
      );
    });

    test('applique le décalage de 5 minutes', () {
      final notifications = scheduler.build(
        todayTimings: todayTimings,
        tomorrowTimings: tomorrowTimings,
        leadTime: PrayerNotificationLeadTime.fiveMinutesBefore,
        now: DateTime(2026, 7, 12, 14, 0),
      );

      final asr = notifications.firstWhere((item) => item.prayerName == 'Asr');

      expect(asr.scheduledAt, DateTime(2026, 7, 12, 16, 53));
      expect(asr.body, 'Dans 5 minutes : Asr');
    });

    test('ignore une prière si le rappel anticipé est déjà passé', () {
      final notifications = scheduler.build(
        todayTimings: todayTimings,
        tomorrowTimings: tomorrowTimings,
        leadTime: PrayerNotificationLeadTime.tenMinutesBefore,
        now: DateTime(2026, 7, 12, 16, 55),
      );

      final todayNames = notifications
          .where((item) => item.id <= 5)
          .map((item) => item.prayerName)
          .toList();

      expect(todayNames, isNot(contains('Asr')));
      expect(todayNames, contains('Maghrib'));
    });

    test('planifie les prières du lendemain', () {
      final notifications = scheduler.build(
        todayTimings: todayTimings,
        tomorrowTimings: tomorrowTimings,
        leadTime: PrayerNotificationLeadTime.atPrayerTime,
        now: DateTime(2026, 7, 12, 22, 0),
      );

      final tomorrowNames = notifications
          .where((item) => item.id >= 6)
          .map((item) => item.prayerName)
          .toList();

      expect(tomorrowNames, [
        'Fajr',
        'Dhuhr',
        'Asr',
        'Maghrib',
        'Isha',
      ]);
      expect(
        notifications.map((item) => item.id).toSet().length,
        notifications.length,
      );
    });
  });
}
