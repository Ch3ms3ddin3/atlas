/// Statut de modération d'un signalement.
enum ContentReportStatus {
  pending,
  reviewed,
  dismissed,
}

/// Libellés persistés côté Supabase.
abstract final class ContentReportStatusLabels {
  static const _fromStorage = {
    'pending': ContentReportStatus.pending,
    'reviewed': ContentReportStatus.reviewed,
    'dismissed': ContentReportStatus.dismissed,
  };

  static ContentReportStatus fromStorage(String? value) {
    return _fromStorage[value] ?? ContentReportStatus.pending;
  }

  static String toStorage(ContentReportStatus status) => status.name;
}
