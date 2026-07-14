import '../domain/content_report_entity_type.dart';
import '../domain/content_report_type.dart';

/// Validation applicative des signalements.
abstract final class ContentReportValidator {
  static const maxDetailsLength = 2000;
  static const maxSlugLength = 120;

  static bool isValidSlug(String slug) {
    final trimmed = slug.trim();
    return trimmed.isNotEmpty && trimmed.length <= maxSlugLength;
  }

  static bool isValidDetails(String details) {
    final trimmed = details.trim();
    return trimmed.isNotEmpty && trimmed.length <= maxDetailsLength;
  }

  static bool isValidReport({
    required ContentReportEntityType entityType,
    required String entitySlug,
    required ContentReportType reportType,
    required String details,
  }) {
    return isValidSlug(entitySlug) && isValidDetails(details);
  }

  static String sanitizeSlug(String slug) => slug.trim();

  static String sanitizeDetails(String details) => details.trim();
}
