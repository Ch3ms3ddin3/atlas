import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/features/content_reports/data/content_reports_preferences_store.dart';
import 'package:atlas/features/content_reports/data/local_content_reports_repository.dart';
import 'package:atlas/features/content_reports/domain/content_report_entity_type.dart';
import 'package:atlas/features/content_reports/domain/content_report_status.dart';
import 'package:atlas/features/content_reports/domain/content_report_type.dart';

void main() {
  group('LocalContentReportsRepository', () {
    test('enregistre un signalement localement', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = LocalContentReportsRepository(
        idProvider: () => 'report-1',
      );

      await repository.load();
      expect(repository.reports, isEmpty);

      final submitted = await repository.submitReport(
        entityType: ContentReportEntityType.place,
        entitySlug: 'place-jardin-majorelle',
        reportType: ContentReportType.outdated,
        details: 'Horaires incorrects',
      );

      expect(submitted, isTrue);
      expect(repository.reports, hasLength(1));
      expect(repository.reports.first.id, 'report-1');
      expect(repository.reports.first.status, ContentReportStatus.pending);
      expect(repository.reports.first.syncPending, isTrue);

      final snapshot = await const ContentReportsPreferencesStore().loadSnapshot();
      expect(snapshot.reports, hasLength(1));
    });

    test('rejette un signalement invalide', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = LocalContentReportsRepository();

      await repository.load();
      final submitted = await repository.submitReport(
        entityType: ContentReportEntityType.price,
        entitySlug: 'price-taxi-marrakech',
        reportType: ContentReportType.other,
        details: '   ',
      );

      expect(submitted, isFalse);
      expect(repository.reports, isEmpty);
    });
  });
}
