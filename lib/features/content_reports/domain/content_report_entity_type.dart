/// Type d'entité éditoriale signalée.
enum ContentReportEntityType {
  price,
  procedure,
  place,
}

/// Libellés persistés côté Supabase.
abstract final class ContentReportEntityTypeLabels {
  static const _fromStorage = {
    'price': ContentReportEntityType.price,
    'procedure': ContentReportEntityType.procedure,
    'place': ContentReportEntityType.place,
  };

  static ContentReportEntityType fromStorage(String? value) {
    return _fromStorage[value] ?? ContentReportEntityType.place;
  }

  static String toStorage(ContentReportEntityType type) => type.name;
}
