import '../domain/models/content_report.dart';
import 'content_reports_local_snapshot.dart';

/// Résultat de fusion local / distant.
class ContentReportsMergeResult {
  const ContentReportsMergeResult({
    required this.reports,
    required this.changed,
    required this.shouldPushLocal,
  });

  final List<ContentReport> reports;
  final bool changed;
  final bool shouldPushLocal;
}

/// Applique les règles de conflit entre signalements locaux et distants.
abstract final class ContentReportsSyncCoordinator {
  static ContentReportsMergeResult merge({
    required ContentReportsLocalSnapshot local,
    List<ContentReport>? remote,
  }) {
    if (remote == null) {
      return ContentReportsMergeResult(
        reports: local.reports,
        changed: false,
        shouldPushLocal: local.syncPending || local.pendingReports.isNotEmpty,
      );
    }

    final merged = _mergeReports(local.reports, remote);
    final changed = !_reportsEquivalent(local.reports, merged);
    final shouldPushLocal =
        local.syncPending || merged.any((report) => report.syncPending);

    return ContentReportsMergeResult(
      reports: merged,
      changed: changed,
      shouldPushLocal: shouldPushLocal,
    );
  }

  static List<ContentReport> _mergeReports(
    List<ContentReport> local,
    List<ContentReport> remote,
  ) {
    final localMap = {for (final report in local) report.id: report};
    final remoteMap = {for (final report in remote) report.id: report};
    final mergedIds = {...localMap.keys, ...remoteMap.keys};

    return [
      for (final id in mergedIds)
        _mergeSingle(
          local: localMap[id],
          remote: remoteMap[id],
        ),
    ];
  }

  static ContentReport _mergeSingle({
    ContentReport? local,
    ContentReport? remote,
  }) {
    if (local == null) return remote!;
    if (remote == null) return local;

    final localUpdatedAt = local.updatedAt.toUtc();
    final remoteUpdatedAt = remote.updatedAt.toUtc();

    if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
      return local.copyWith(
        status: remote.status,
        updatedAt: remote.updatedAt,
        syncPending: false,
      );
    }

    if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
      return local;
    }

    // Timestamps égaux — le statut distant (modération) l'emporte.
    return local.copyWith(
      status: remote.status,
      syncPending: local.syncPending,
    );
  }

  static bool _reportsEquivalent(
    List<ContentReport> left,
    List<ContentReport> right,
  ) {
    final leftMap = {for (final report in left) report.id: report};
    final rightMap = {for (final report in right) report.id: report};
    if (leftMap.length != rightMap.length) return false;

    for (final entry in leftMap.entries) {
      final other = rightMap[entry.key];
      if (other == null) return false;
      if (!_reportEqual(entry.value, other)) return false;
    }
    return true;
  }

  static bool _reportEqual(ContentReport a, ContentReport b) {
    return a.id == b.id &&
        a.entityType == b.entityType &&
        a.entitySlug == b.entitySlug &&
        a.reportType == b.reportType &&
        a.details == b.details &&
        a.status == b.status &&
        a.createdAt.toUtc() == b.createdAt.toUtc() &&
        a.updatedAt.toUtc() == b.updatedAt.toUtc() &&
        a.syncPending == b.syncPending;
  }
}
