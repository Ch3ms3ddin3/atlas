import '../domain/models/content_report.dart';

/// État local des signalements et métadonnées de synchronisation.
class ContentReportsLocalSnapshot {
  const ContentReportsLocalSnapshot({
    required this.reports,
    this.syncPending = false,
  });

  final List<ContentReport> reports;
  final bool syncPending;

  List<ContentReport> get pendingReports =>
      reports.where((report) => report.syncPending).toList(growable: false);
}
