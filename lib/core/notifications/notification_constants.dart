/// Identifiants stables pour les notifications de prière.
abstract final class NotificationConstants {
  static const channelId = 'atlas_prayer_notifications';
  static const channelName = 'Horaires de prière';
  static const channelDescription = 'Rappels pour les horaires de prière';

  /// IDs 1–5 = prières du jour, 6–10 = prières du lendemain.
  static const prayerNotificationIdStart = 1;
  static const prayerNotificationIdEnd = 10;
}
