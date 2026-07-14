import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/content_reports/data/content_report_record_mapper.dart';
import 'package:atlas/features/content_reports/domain/content_report_entity_type.dart';
import 'package:atlas/features/content_reports/domain/content_report_status.dart';
import 'package:atlas/features/content_reports/domain/content_report_type.dart';
import 'package:atlas/features/content_reports/domain/models/content_report.dart';

void main() {
  group('ContentReportRecordMapper', () {
    test('convertit une ligne Supabase vers un ContentReport', () {
      final report = ContentReportRecordMapper.fromRow({
        'id': 'report-1',
        'entity_type': 'procedure',
        'entity_slug': 'procedure-renouveler-cin',
        'report_type': 'missing_info',
        'details': 'Étape manquante',
        'status': 'reviewed',
        'created_at': '2026-07-10T12:00:00.000Z',
        'updated_at': '2026-07-12T10:00:00.000Z',
      });

      expect(report.id, 'report-1');
      expect(report.entityType, ContentReportEntityType.procedure);
      expect(report.reportType, ContentReportType.missingInfo);
      expect(report.status, ContentReportStatus.reviewed);
      expect(report.syncPending, isFalse);
    });

    test('convertit un ContentReport vers une ligne d insertion', () {
      final row = ContentReportRecordMapper.toInsertRow(
        userId: 'user-1',
        report: ContentReport(
          id: 'report-2',
          entityType: ContentReportEntityType.price,
          entitySlug: 'price-taxi-marrakech',
          reportType: ContentReportType.incorrect,
          details: 'Montant erroné',
          status: ContentReportStatus.pending,
          createdAt: DateTime.utc(2026, 7, 10, 12),
          updatedAt: DateTime.utc(2026, 7, 10, 12),
        ),
      );

      expect(row['id'], 'report-2');
      expect(row['user_id'], 'user-1');
      expect(row['entity_type'], 'price');
      expect(row['report_type'], 'incorrect');
      expect(row['status'], 'pending');
    });
  });
}
