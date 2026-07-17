import '../domain/models/at_vehicle.dart';
import 'at_preferences_store.dart';

/// Fusion véhicules AT — LWW par id, local prioritaire si syncPending.
abstract final class AtSyncCoordinator {
  static AtLocalSnapshot merge({
    required AtLocalSnapshot local,
    List<AtVehicle>? remote,
  }) {
    if (remote == null) return local;

    final localMap = {
      for (final v in local.vehicles) v.id: v,
    };
    final remoteMap = {
      for (final v in remote) v.id: v,
    };
    final merged = <String, AtVehicle>{};

    for (final id in {...localMap.keys, ...remoteMap.keys}) {
      final localVehicle = localMap[id];
      final remoteVehicle = remoteMap[id];
      if (localVehicle == null) {
        merged[id] = remoteVehicle!;
        continue;
      }
      if (remoteVehicle == null) {
        merged[id] = localVehicle;
        continue;
      }
      if (local.syncPending) {
        merged[id] = localVehicle;
        continue;
      }
      merged[id] = remoteVehicle.updatedAt.isAfter(localVehicle.updatedAt)
          ? remoteVehicle
          : localVehicle;
    }

    return AtLocalSnapshot(
      vehicles: merged.values.toList(growable: false),
      notificationsEnabled: local.notificationsEnabled,
      notificationPromptShown: local.notificationPromptShown,
      syncPending: local.syncPending,
    );
  }
}
