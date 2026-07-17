import '../domain/models/trip.dart';

/// Fusion LWW des voyages locaux et distants.
abstract final class ItinerarySyncCoordinator {
  static List<Trip> merge({
    required List<Trip> local,
    required List<Trip> remote,
  }) {
    final byId = <String, Trip>{
      for (final trip in local) trip.id: trip,
    };

    for (final remoteTrip in remote) {
      final existing = byId[remoteTrip.id];
      if (existing == null) {
        byId[remoteTrip.id] = remoteTrip.copyWith(syncPending: false);
        continue;
      }
      if (existing.syncPending) {
        // Pending local wins until pushed.
        continue;
      }
      if (remoteTrip.updatedAt.isAfter(existing.updatedAt)) {
        byId[remoteTrip.id] = remoteTrip.copyWith(syncPending: false);
      } else if (remoteTrip.updatedAt.isAtSameMomentAs(existing.updatedAt) &&
          existing.isActive != remoteTrip.isActive) {
        // Tie: prefer local.
        continue;
      }
    }

    final merged = byId.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return merged;
  }
}
