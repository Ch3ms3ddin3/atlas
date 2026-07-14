import 'package:flutter/foundation.dart';

import 'content_report_entity_type.dart';
import 'content_report_type.dart';
import 'models/content_report.dart';

/// Accès aux signalements — indépendant de Supabase.
abstract class ContentReportsRepository extends ChangeNotifier {
  ContentReportsRepository.base();

  bool get isLoaded;

  List<ContentReport> get reports;

  Future<void> load();

  Future<bool> submitReport({
    required ContentReportEntityType entityType,
    required String entitySlug,
    required ContentReportType reportType,
    required String details,
  });
}
