/// Type d'arrêt dans un itinéraire Atlas.
enum ItineraryStopType { place, event, custom, buffer }

/// Provenance d'un arrêt.
enum ItineraryStopSource { user, ai, favorite }

/// Statut d'un voyage.
enum TripStatus { draft, active, archived }

/// Fournisseur de réservation futur (stub extensible).
abstract class BookingProvider {
  String get id;
  String get displayName;
  bool get isAvailable;
}

/// Stub — aucun booking dans ce milestone.
class NoopBookingProvider implements BookingProvider {
  const NoopBookingProvider();

  @override
  String get id => 'noop';

  @override
  String get displayName => 'Aucun';

  @override
  bool get isAvailable => false;
}

/// Longueur max d'un itinéraire (jours civils inclusifs).
abstract final class ItineraryLimits {
  static const maxDays = 14;
}
