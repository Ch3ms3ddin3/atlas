/// Délai avant la prière pour la notification locale.
enum PrayerNotificationLeadTime {
  disabled,
  atPrayerTime,
  fiveMinutesBefore,
  tenMinutesBefore;

  int get offsetMinutes => switch (this) {
        PrayerNotificationLeadTime.disabled => 0,
        PrayerNotificationLeadTime.atPrayerTime => 0,
        PrayerNotificationLeadTime.fiveMinutesBefore => 5,
        PrayerNotificationLeadTime.tenMinutesBefore => 10,
      };

  String get label => switch (this) {
        PrayerNotificationLeadTime.disabled => 'Désactivé',
        PrayerNotificationLeadTime.atPrayerTime => 'À l\'heure de la prière',
        PrayerNotificationLeadTime.fiveMinutesBefore => '5 minutes avant',
        PrayerNotificationLeadTime.tenMinutesBefore => '10 minutes avant',
      };

  static PrayerNotificationLeadTime fromStorage(String? value) {
    return PrayerNotificationLeadTime.values.firstWhere(
      (option) => option.name == value,
      orElse: () => PrayerNotificationLeadTime.disabled,
    );
  }
}
