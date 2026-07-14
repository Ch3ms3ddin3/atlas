import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/config/atlas_env.dart';
import 'package:atlas/features/content_reports/data/content_reports_preferences_store.dart';
import 'package:atlas/features/content_reports/data/supabase_content_reports_repository.dart';
import 'package:atlas/features/content_reports/data/syncing_content_reports_repository.dart';
import 'package:atlas/features/content_reports/domain/content_report_entity_type.dart';
import 'package:atlas/features/content_reports/domain/content_report_status.dart';
import 'package:atlas/features/content_reports/domain/content_report_type.dart';
import 'package:atlas/features/content_reports/domain/models/content_report.dart';

void main() {
  group('SyncingContentReportsRepository', () {
    test('retombe sur le local quand la synchronisation est indisponible', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ContentReportsPreferencesStore();
      final repository = SyncingContentReportsRepository(
        store: store,
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: '',
          supabaseAnonKey: '',
        ),
        remote: _FailingRemoteRepository(),
        userIdProvider: () => 'user-1',
        idProvider: () => 'report-1',
      );

      await repository.load();

      expect(repository.isLoaded, isTrue);
      expect(repository.reports, isEmpty);
    });

    test('applique les statuts distants au chargement', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ContentReportsPreferencesStore();
      final repository = SyncingContentReportsRepository(
        store: store,
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: 'https://example.supabase.co',
          supabaseAnonKey: 'anon-key',
        ),
        remote: _StubRemoteRepository(),
        userIdProvider: () => 'user-1',
        syncEnabledOverride: true,
        syncTimeout: const Duration(milliseconds: 100),
      );

      await repository.load();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(repository.reports, hasLength(1));
      expect(repository.reports.first.status, ContentReportStatus.reviewed);
    });

    test('marque sync_pending quand le push distant échoue', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ContentReportsPreferencesStore();
      final repository = SyncingContentReportsRepository(
        store: store,
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: 'https://example.supabase.co',
          supabaseAnonKey: 'anon-key',
        ),
        remote: _FailingRemoteRepository(),
        userIdProvider: () => 'user-1',
        syncEnabledOverride: true,
        idProvider: () => 'report-1',
      );

      final submitted = await repository.submitReport(
        entityType: ContentReportEntityType.place,
        entitySlug: 'place-jardin-majorelle',
        reportType: ContentReportType.outdated,
        details: 'Horaires incorrects',
      );

      expect(submitted, isTrue);
      final snapshot = await store.loadSnapshot();
      expect(snapshot.syncPending, isTrue);
      expect(snapshot.reports.first.syncPending, isTrue);
    });
  });
}

class _FailingRemoteRepository extends SupabaseContentReportsRepository {
  _FailingRemoteRepository()
      : super(clientProvider: () => throw StateError('no client'));

  @override
  Future<List<ContentReport>> fetch(String userId) async {
    throw Exception('network error');
  }

  @override
  Future<void> insert({
    required String userId,
    required ContentReport report,
  }) async {
    throw Exception('network error');
  }
}

class _StubRemoteRepository extends SupabaseContentReportsRepository {
  _StubRemoteRepository()
      : super(clientProvider: () => throw StateError('no client'));

  @override
  Future<List<ContentReport>> fetch(String userId) async {
    return [
      ContentReport(
        id: 'report-remote',
        entityType: ContentReportEntityType.place,
        entitySlug: 'place-jardin-majorelle',
        reportType: ContentReportType.outdated,
        details: 'Horaires incorrects',
        status: ContentReportStatus.reviewed,
        createdAt: DateTime.utc(2026, 7, 10, 12),
        updatedAt: DateTime.utc(2026, 7, 12, 10),
      ),
    ];
  }

  @override
  Future<void> insert({
    required String userId,
    required ContentReport report,
  }) async {}
}
