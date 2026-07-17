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
        CloudSyncPhase.idle => 'Synchronisation en attente',
        CloudSyncPhase.syncing => 'Synchronisation…',
        CloudSyncPhase.synced => 'À jour',
        CloudSyncPhase.offline => 'Hors ligne — données locales',
        CloudSyncPhase.error => 'Synchronisation interrompue',
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
}
