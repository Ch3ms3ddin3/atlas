import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/notifications/notification_preferences_store.dart';
import 'package:atlas/core/notifications/prayer_notification_lead_time.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NotificationPreferencesStore', () {
    test('renvoie disabled par défaut', () async {
      SharedPreferences.setMockInitialValues({});
      const store = NotificationPreferencesStore();

      final leadTime = await store.load();

      expect(leadTime, PrayerNotificationLeadTime.disabled);
    });

    test('persiste et recharge le délai choisi', () async {
      SharedPreferences.setMockInitialValues({});
      const store = NotificationPreferencesStore();

      await store.save(PrayerNotificationLeadTime.fiveMinutesBefore);
      final leadTime = await store.load();

      expect(leadTime, PrayerNotificationLeadTime.fiveMinutesBefore);
    });

    test('supprime la clé quand les rappels sont désactivés', () async {
      SharedPreferences.setMockInitialValues({
        'prayer_notification_lead_time':
            PrayerNotificationLeadTime.atPrayerTime.name,
      });
      const store = NotificationPreferencesStore();

      await store.save(PrayerNotificationLeadTime.disabled);
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.containsKey('prayer_notification_lead_time'), isFalse);
      expect(await store.load(), PrayerNotificationLeadTime.disabled);
    });
  });
}
