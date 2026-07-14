import '../domain/models/favorite_key.dart';
import '../domain/models/favorite_record.dart';
import 'favorites_local_snapshot.dart';

/// Résultat de fusion local / distant.
class FavoritesMergeResult {
  const FavoritesMergeResult({
    required this.records,
    required this.activeKeys,
    required this.changed,
    required this.shouldPushLocal,
  });

  final List<FavoriteRecord> records;
  final Set<FavoriteKey> activeKeys;
  final bool changed;
  final bool shouldPushLocal;
}

/// Applique les règles de conflit entre favoris locaux et distants.
abstract final class FavoritesSyncCoordinator {
  static FavoritesMergeResult merge({
    required FavoritesLocalSnapshot local,
    List<FavoriteRecord>? remote,
  }) {
    if (remote == null) {
      final activeKeys = _activeKeys(local.records);
      return FavoritesMergeResult(
        records: local.records,
        activeKeys: activeKeys,
        changed: false,
        shouldPushLocal: local.syncPending,
      );
    }

    final mergedRecords = _mergeRecords(
      local.records,
      remote,
      preferLocalWhenPending: local.syncPending,
    );
    final activeKeys = _activeKeys(mergedRecords);
    final changed = !_recordsEquivalent(local.records, mergedRecords);
    final shouldPushLocal =
        local.syncPending || _localShouldPush(local.records, remote, mergedRecords);

    return FavoritesMergeResult(
      records: mergedRecords,
      activeKeys: activeKeys,
      changed: changed,
      shouldPushLocal: shouldPushLocal,
    );
  }

  static List<FavoriteRecord> _mergeRecords(
    List<FavoriteRecord> local,
    List<FavoriteRecord> remote, {
    required bool preferLocalWhenPending,
  }) {
    final localMap = _toMap(local);
    final remoteMap = _toMap(remote);
    final merged = <FavoriteKey, FavoriteRecord>{};

    for (final key in {...localMap.keys, ...remoteMap.keys}) {
      final localRecord = localMap[key];
      final remoteRecord = remoteMap[key];

      if (localRecord == null) {
        merged[key] = remoteRecord!;
        continue;
      }
      if (remoteRecord == null) {
        merged[key] = localRecord;
        continue;
      }

      merged[key] = _pickLatest(
        localRecord,
        remoteRecord,
        preferLocalWhenPending: preferLocalWhenPending,
      );
    }

    return merged.values.toList(growable: false);
  }

  static FavoriteRecord _pickLatest(
    FavoriteRecord local,
    FavoriteRecord remote, {
    bool preferLocalWhenPending = false,
  }) {
    if (preferLocalWhenPending) return local;

    final localUpdatedAt = local.updatedAt.toUtc();
    final remoteUpdatedAt = remote.updatedAt.toUtc();

    if (localUpdatedAt.isAfter(remoteUpdatedAt)) return local;
    if (remoteUpdatedAt.isAfter(localUpdatedAt)) return remote;

    // Timestamps égaux — le local l'emporte.
    return local;
  }

  static bool _localShouldPush(
    List<FavoriteRecord> local,
    List<FavoriteRecord> remote,
    List<FavoriteRecord> merged,
  ) {
    final localMap = _toMap(local);
    final remoteMap = _toMap(remote);
    final mergedMap = _toMap(merged);

    for (final entry in mergedMap.entries) {
      final localRecord = localMap[entry.key];
      if (localRecord == null) continue;
      if (entry.value != localRecord) continue;

      final remoteRecord = remoteMap[entry.key];
      if (remoteRecord == null) return true;
      if (localRecord.updatedAt.toUtc().isAfter(remoteRecord.updatedAt.toUtc())) {
        return true;
      }
      if (localRecord.updatedAt.toUtc() == remoteRecord.updatedAt.toUtc()) {
        return true;
      }
    }

    return false;
  }

  static Map<FavoriteKey, FavoriteRecord> _toMap(List<FavoriteRecord> records) {
    return {
      for (final record in records) record.key: record,
    };
  }

  static Set<FavoriteKey> _activeKeys(List<FavoriteRecord> records) {
    return {
      for (final record in records)
        if (record.isActive) record.key,
    };
  }

  static bool snapshotsEquivalent(
    FavoritesLocalSnapshot left,
    FavoritesLocalSnapshot right,
  ) {
    return left.syncPending == right.syncPending &&
        _recordsEquivalent(left.records, right.records);
  }

  static bool _recordsEquivalent(
    List<FavoriteRecord> left,
    List<FavoriteRecord> right,
  ) {
    final leftMap = _toMap(left);
    final rightMap = _toMap(right);
    if (leftMap.length != rightMap.length) return false;

    for (final entry in leftMap.entries) {
      final other = rightMap[entry.key];
      if (other == null) return false;
      if (!_recordEqual(entry.value, other)) return false;
    }
    return true;
  }

  static bool _recordEqual(FavoriteRecord a, FavoriteRecord b) {
    return a.entityType == b.entityType &&
        a.entitySlug == b.entitySlug &&
        a.isActive == b.isActive &&
        a.updatedAt.toUtc() == b.updatedAt.toUtc();
  }
}
