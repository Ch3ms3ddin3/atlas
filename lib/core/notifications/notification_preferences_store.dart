import 'package:shared_preferences/shared_preferences.dart';

import 'prayer_notification_lead_time.dart';

/// Persiste le choix de rappel de prière (défaut : désactivé).
class NotificationPreferencesStore {
  const NotificationPreferencesStore();

  static const _key = 'prayer_notification_lead_time';

  Future<PrayerNotificationLeadTime> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PrayerNotificationLeadTime.fromStorage(prefs.getString(_key));
  }

  Future<void> save(PrayerNotificationLeadTime leadTime) async {
    final prefs = await SharedPreferences.getInstance();
    if (leadTime == PrayerNotificationLeadTime.disabled) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(_key, leadTime.name);
  }
}
