import '../content_report_entity_type.dart';
import '../content_report_status.dart';
import '../content_report_type.dart';

/// Signalement utilisateur sur une entité éditoriale.
class ContentReport {
  const ContentReport({
    required this.id,
    required this.entityType,
    required this.entitySlug,
    required this.reportType,
    required this.details,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.syncPending = false,
  });

  final String id;
  final ContentReportEntityType entityType;
  final String entitySlug;
  final ContentReportType reportType;
  final String details;
  final ContentReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool syncPending;

  ContentReport copyWith({
    String? id,
    ContentReportEntityType? entityType,
    String? entitySlug,
    ContentReportType? reportType,
    String? details,
    ContentReportStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? syncPending,
  }) {
    return ContentReport(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entitySlug: entitySlug ?? this.entitySlug,
      reportType: reportType ?? this.reportType,
      details: details ?? this.details,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncPending: syncPending ?? this.syncPending,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entityType': entityType.name,
      'entitySlug': entitySlug,
      'reportType': ContentReportTypeLabels.toStorage(reportType),
      'details': details,
      'status': status.name,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'syncPending': syncPending,
    };
  }

  static ContentReport? fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final entitySlug = json['entitySlug'] as String?;
    final details = json['details'] as String?;
    final createdAtRaw = json['createdAt'] as String?;
    final updatedAtRaw = json['updatedAt'] as String?;

    if (id == null ||
        id.isEmpty ||
        entitySlug == null ||
        entitySlug.isEmpty ||
        details == null ||
        details.isEmpty ||
        createdAtRaw == null ||
        updatedAtRaw == null) {
      return null;
    }

    return ContentReport(
      id: id,
      entityType: ContentReportEntityTypeLabels.fromStorage(
        json['entityType'] as String?,
      ),
      entitySlug: entitySlug,
      reportType: ContentReportTypeLabels.fromStorage(
        json['reportType'] as String?,
      ),
      details: details,
      status: ContentReportStatusLabels.fromStorage(
        json['status'] as String?,
      ),
      createdAt: DateTime.parse(createdAtRaw).toUtc(),
      updatedAt: DateTime.parse(updatedAtRaw).toUtc(),
      syncPending: json['syncPending'] as bool? ?? false,
    );
  }
}
