import 'package:shared_preferences/shared_preferences.dart';

/// État de synchronisation cloud — local, sans données sensibles.
enum CloudSyncPhase {
  idle,
  syncing,
  synced,
  offline,
  error,
}

class CloudSyncStatus {
  const CloudSyncStatus({
    required this.phase,
    this.lastSyncedAt,
    this.errorMessage,
  });

  const CloudSyncStatus.idle() : this(phase: CloudSyncPhase.idle);

  final CloudSyncPhase phase;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  String get labelFr => switch (phase) {
        CloudSyncPhase.idle => 'Préférences en attente de sync',
        CloudSyncPhase.syncing => 'Synchronisation des préférences…',
        CloudSyncPhase.synced => 'Préférences synchronisées',
        CloudSyncPhase.offline =>
          'Mode local — sync cloud réservée au compte',
        CloudSyncPhase.error => 'Sync préférences interrompue',
      };
}

/// Persiste le dernier succès de sync (horodatage uniquement).
class CloudSyncStatusStore {
  const CloudSyncStatusStore();

  static const lastSyncedAtKey = 'cloud_sync_last_synced_at';

  Future<DateTime?> loadLastSyncedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(lastSyncedAtKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  Future<void> markSynced(DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastSyncedAtKey, at.toUtc().toIso8601String());
  }

  /// Efface l'horodatage de sync (changement d'identité).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(lastSyncedAtKey);
  }
}
