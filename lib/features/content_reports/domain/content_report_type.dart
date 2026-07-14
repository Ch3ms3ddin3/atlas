/// Motif du signalement.
enum ContentReportType {
  outdated,
  incorrect,
  missingInfo,
  other,
}

/// Libellés persistés côté Supabase.
abstract final class ContentReportTypeLabels {
  static const _fromStorage = {
    'outdated': ContentReportType.outdated,
    'incorrect': ContentReportType.incorrect,
    'missing_info': ContentReportType.missingInfo,
    'other': ContentReportType.other,
  };

  static const _toStorage = {
    ContentReportType.outdated: 'outdated',
    ContentReportType.incorrect: 'incorrect',
    ContentReportType.missingInfo: 'missing_info',
    ContentReportType.other: 'other',
  };

  static ContentReportType fromStorage(String? value) {
    return _fromStorage[value] ?? ContentReportType.other;
  }

  static String toStorage(ContentReportType type) {
    return _toStorage[type] ?? 'other';
  }
}
