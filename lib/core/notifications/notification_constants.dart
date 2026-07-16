/// Identifiants stables pour les notifications Atlas.
abstract final class NotificationConstants {
  static const channelId = 'atlas_prayer_notifications';
  static const channelName = 'Horaires de prière';
  static const channelDescription = 'Rappels pour les horaires de prière';

  /// IDs 1–5 = prières du jour, 6–10 = prières du lendemain.
  static const prayerNotificationIdStart = 1;
  static const prayerNotificationIdEnd = 10;

  static const atChannelId = 'atlas_at_notifications';
  static const atChannelName = 'Mes véhicules au Maroc';
  static const atChannelDescription =
      'Rappels d\'échéance d\'admission temporaire';

  /// IDs 1000–1999 réservés aux rappels AT (slot × 10 + offset).
  static const atNotificationIdStart = 1000;
  static const atNotificationIdEnd = 1999;
}
