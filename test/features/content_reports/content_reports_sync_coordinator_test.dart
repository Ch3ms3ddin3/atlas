import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/content_reports/data/content_reports_local_snapshot.dart';
import 'package:atlas/features/content_reports/data/content_reports_sync_coordinator.dart';
import 'package:atlas/features/content_reports/domain/content_report_entity_type.dart';
import 'package:atlas/features/content_reports/domain/content_report_status.dart';
import 'package:atlas/features/content_reports/domain/content_report_type.dart';
import 'package:atlas/features/content_reports/domain/models/content_report.dart';

void main() {
  final createdAt = DateTime.utc(2026, 7, 10, 12);
  final localUpdatedAt = DateTime.utc(2026, 7, 10, 12);
  final remoteUpdatedAt = DateTime.utc(2026, 7, 12, 12);

  ContentReport localReport({
    ContentReportStatus status = ContentReportStatus.pending,
    DateTime? updatedAt,
    bool syncPending = true,
  }) {
    return ContentReport(
      id: 'report-1',
      entityType: ContentReportEntityType.place,
      entitySlug: 'place-jardin-majorelle',
      reportType: ContentReportType.outdated,
      details: 'Horaires incorrects',
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? localUpdatedAt,
      syncPending: syncPending,
    );
  }

  group('ContentReportsSyncCoordinator', () {
    test('conserve le local quand le distant est absent', () {
      final result = ContentReportsSyncCoordinator.merge(
        local: ContentReportsLocalSnapshot(
          reports: [localReport()],
          syncPending: true,
        ),
      );

      expect(result.reports, hasLength(1));
      expect(result.changed, isFalse);
      expect(result.shouldPushLocal, isTrue);
    });

    test('ajoute les signalements distants absents en local', () {
      final result = ContentReportsSyncCoordinator.merge(
        local: const ContentReportsLocalSnapshot(reports: []),
        remote: [
          localReport(
            status: ContentReportStatus.reviewed,
            updatedAt: remoteUpdatedAt,
            syncPending: false,
          ),
        ],
      );

      expect(result.reports.first.status, ContentReportStatus.reviewed);
      expect(result.changed, isTrue);
      expect(result.shouldPushLocal, isFalse);
    });

    test('applique le statut distant quand il est plus récent', () {
      final result = ContentReportsSyncCoordinator.merge(
        local: ContentReportsLocalSnapshot(
          reports: [localReport(syncPending: false)],
        ),
        remote: [
          localReport(
            status: ContentReportStatus.reviewed,
            updatedAt: remoteUpdatedAt,
            syncPending: false,
          ),
        ],
      );

      expect(result.reports.first.status, ContentReportStatus.reviewed);
      expect(result.reports.first.syncPending, isFalse);
      expect(result.changed, isTrue);
    });

    test('conserve le local quand il est plus récent', () {
      final result = ContentReportsSyncCoordinator.merge(
        local: ContentReportsLocalSnapshot(
          reports: [
            localReport(
              updatedAt: remoteUpdatedAt.add(const Duration(hours: 1)),
            ),
          ],
        ),
        remote: [
          localReport(
            status: ContentReportStatus.reviewed,
            updatedAt: remoteUpdatedAt,
            syncPending: false,
          ),
        ],
      );

      expect(result.reports.first.status, ContentReportStatus.pending);
      expect(result.shouldPushLocal, isTrue);
    });

    test('le statut distant l emporte à timestamps égaux', () {
      final result = ContentReportsSyncCoordinator.merge(
        local: ContentReportsLocalSnapshot(
          reports: [localReport(updatedAt: remoteUpdatedAt)],
        ),
        remote: [
          localReport(
            status: ContentReportStatus.dismissed,
            updatedAt: remoteUpdatedAt,
            syncPending: false,
          ),
        ],
      );

      expect(result.reports.first.status, ContentReportStatus.dismissed);
      expect(result.changed, isTrue);
    });
  });
}
