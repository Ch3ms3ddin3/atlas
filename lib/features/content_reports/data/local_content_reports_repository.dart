import '../../../core/uuid/atlas_uuid.dart';
import '../domain/content_report_entity_type.dart';
import '../domain/content_report_status.dart';
import '../domain/content_report_type.dart';
import '../domain/content_reports_repository.dart';
import '../domain/models/content_report.dart';
import 'content_report_validator.dart';
import 'content_reports_preferences_store.dart';

/// Signalements locaux uniquement — repli permanent hors ligne.
class LocalContentReportsRepository extends ContentReportsRepository {
  LocalContentReportsRepository({
    ContentReportsPreferencesStore? store,
    String Function()? idProvider,
  })  : _store = store ?? const ContentReportsPreferencesStore(),
        _idProvider = idProvider ?? AtlasUuid.v4,
        super.base();

  final ContentReportsPreferencesStore _store;
  final String Function() _idProvider;

  List<ContentReport> _reports = const [];
  bool _isLoaded = false;

  @override
  List<ContentReport> get reports => List.unmodifiable(_reports);

  @override
  bool get isLoaded => _isLoaded;

  @override
  Future<void> load() async {
    final snapshot = await _store.loadSnapshot();
    _reports = snapshot.reports;
    _isLoaded = true;
    notifyListeners();
  }

  @override
  Future<bool> submitReport({
    required ContentReportEntityType entityType,
    required String entitySlug,
    required ContentReportType reportType,
    required String details,
  }) async {
    final sanitizedSlug = ContentReportValidator.sanitizeSlug(entitySlug);
    final sanitizedDetails = ContentReportValidator.sanitizeDetails(details);
    if (!ContentReportValidator.isValidReport(
      entityType: entityType,
      entitySlug: sanitizedSlug,
      reportType: reportType,
      details: sanitizedDetails,
    )) {
      return false;
    }

    final now = DateTime.now().toUtc();
    final report = ContentReport(
      id: _idProvider(),
      entityType: entityType,
      entitySlug: sanitizedSlug,
      reportType: reportType,
      details: sanitizedDetails,
      status: ContentReportStatus.pending,
      createdAt: now,
      updatedAt: now,
      syncPending: true,
    );

    final snapshot = await _store.loadSnapshot();
    final reports = [...snapshot.reports, report];
    await _store.saveReports(reports);

    _reports = reports;
    notifyListeners();
    return true;
  }
}
