import '../domain/models/at_vehicle.dart';

/// Calculs d'échéance AT — dates civiles Africa/Casablanca (UTC+1 permanent).
abstract final class AtCalculator {
  /// Seuils d'alerte (jours restants), hors jour d'expiration (0).
  static const warningThresholds = <int>[30, 15, 7, 3, 1];

  static DateTime casablancaNow([DateTime? referenceUtc]) {
    final utc = (referenceUtc ?? DateTime.now()).toUtc();
    return utc.add(const Duration(hours: 1));
  }

  static DateTime calendarDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Calcule la date d'expiration à partir de l'entrée + durée.
  static DateTime expiryFromEntry({
    required DateTime entryDate,
    required int durationDays,
  }) {
    assert(durationDays > 0);
    final entry = calendarDay(entryDate);
    return entry.add(Duration(days: durationDays));
  }

  /// Jours restants : négatif si expiré.
  static int remainingDays({
    required DateTime expiryDate,
    DateTime? now,
  }) {
    final today = calendarDay(now ?? casablancaNow());
    final expiry = calendarDay(expiryDate);
    return expiry.difference(today).inDays;
  }

  static bool isExpired({
    required DateTime expiryDate,
    DateTime? now,
  }) {
    return remainingDays(expiryDate: expiryDate, now: now) < 0;
  }

  static AtUrgencyStatus status({
    required DateTime expiryDate,
    DateTime? now,
  }) {
    final remaining = remainingDays(expiryDate: expiryDate, now: now);
    if (remaining < 0) return AtUrgencyStatus.expired;
    if (remaining <= 7) return AtUrgencyStatus.critical;
    if (remaining <= 30) return AtUrgencyStatus.warning;
    return AtUrgencyStatus.ok;
  }

  /// Progression 0–1 (1 = plein de jours, 0 = expiré / épuisé).
  static double progress({
    required int remainingDays,
    required int durationDays,
  }) {
    if (durationDays <= 0) return 0;
    if (remainingDays <= 0) return 0;
    return (remainingDays / durationDays).clamp(0.0, 1.0);
  }

  static String remainingLabel({
    required int remainingDays,
  }) {
    if (remainingDays < 0) {
      final ago = -remainingDays;
      if (ago == 1) return 'Expiré depuis 1 jour';
      return 'Expiré depuis $ago jours';
    }
    if (remainingDays == 0) return 'Expire aujourd\'hui';
    if (remainingDays == 1) return '1 jour restant';
    return '$remainingDays jours restants';
  }

  static String statusLabel(AtUrgencyStatus status) {
    return switch (status) {
      AtUrgencyStatus.ok => 'En cours',
      AtUrgencyStatus.warning => 'À surveiller',
      AtUrgencyStatus.critical => 'Urgent',
      AtUrgencyStatus.expired => 'Expiré',
    };
  }

  /// Véhicule le plus urgent parmi une liste active.
  static AtVehicle? mostUrgent(
    Iterable<AtVehicle> vehicles, {
    DateTime? now,
  }) {
    final active = vehicles.where((v) => v.isActive).toList();
    if (active.isEmpty) return null;
    active.sort((a, b) {
      final aDays = remainingDays(expiryDate: a.expiryDate, now: now);
      final bDays = remainingDays(expiryDate: b.expiryDate, now: now);
      final byDays = aDays.compareTo(bDays);
      if (byDays != 0) return byDays;
      return a.label.compareTo(b.label);
    });
    return active.first;
  }
}
