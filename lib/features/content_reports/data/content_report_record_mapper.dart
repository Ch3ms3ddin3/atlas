import '../domain/content_report_entity_type.dart';
import '../domain/content_report_status.dart';
import '../domain/content_report_type.dart';
import '../domain/models/content_report.dart';

/// Convertit les lignes Supabase vers les modèles de signalement.
abstract final class ContentReportRecordMapper {
  static ContentReport fromRow(Map<String, dynamic> row) {
    return ContentReport(
      id: row['id'] as String,
      entityType: ContentReportEntityTypeLabels.fromStorage(
        row['entity_type'] as String?,
      ),
      entitySlug: row['entity_slug'] as String,
      reportType: ContentReportTypeLabels.fromStorage(
        row['report_type'] as String?,
      ),
      details: row['details'] as String,
      status: ContentReportStatusLabels.fromStorage(
        row['status'] as String?,
      ),
      createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
      syncPending: false,
    );
  }

  static Map<String, dynamic> toInsertRow({
    required String userId,
    required ContentReport report,
  }) {
    return {
      'id': report.id,
      'user_id': userId,
      'entity_type': ContentReportEntityTypeLabels.toStorage(report.entityType),
      'entity_slug': report.entitySlug,
      'report_type': ContentReportTypeLabels.toStorage(report.reportType),
      'details': report.details,
      'status': ContentReportStatusLabels.toStorage(report.status),
      'created_at': report.createdAt.toUtc().toIso8601String(),
      'updated_at': report.updatedAt.toUtc().toIso8601String(),
    };
  }
}
