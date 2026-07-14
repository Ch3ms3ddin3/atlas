import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/config/atlas_env.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../../core/uuid/atlas_uuid.dart';
import '../domain/content_report_entity_type.dart';
import '../domain/content_report_status.dart';
import '../domain/content_report_type.dart';
import '../domain/content_reports_repository.dart';
import '../domain/models/content_report.dart';
import 'content_report_validator.dart';
import 'content_reports_local_snapshot.dart';
import 'content_reports_preferences_store.dart';
import 'content_reports_sync_coordinator.dart';
import 'supabase_content_reports_repository.dart';

/// Signalements local d'abord, synchronisation Supabase silencieuse en arrière-plan.
class SyncingContentReportsRepository extends ContentReportsRepository {
  SyncingContentReportsRepository({
    ContentReportsPreferencesStore? store,
    SupabaseContentReportsRepository? remote,
    AtlasEnv? env,
    String? Function()? userIdProvider,
    String Function()? idProvider,
    Duration? syncTimeout,
    @visibleForTesting this.syncEnabledOverride = false,
  })  : _store = store ?? const ContentReportsPreferencesStore(),
        _remote = remote ?? const SupabaseContentReportsRepository(),
        _env = env ?? AtlasEnv.fromCompileTime(),
        _userIdProvider = userIdProvider ?? _defaultUserId,
        _idProvider = idProvider ?? AtlasUuid.v4,
        _syncTimeout = syncTimeout ?? const Duration(seconds: 5),
        super.base();

  final ContentReportsPreferencesStore _store;
  final SupabaseContentReportsRepository _remote;
  final AtlasEnv _env;
  final String? Function() _userIdProvider;
  final String Function() _idProvider;
  final Duration _syncTimeout;
  @visibleForTesting
  final bool syncEnabledOverride;

  List<ContentReport> _reports = const [];
  bool _isLoaded = false;
  bool _syncInProgress = false;

  @override
  List<ContentReport> get reports => List.unmodifiable(_reports);

  @override
  bool get isLoaded => _isLoaded;

  static String? _defaultUserId() {
    return SupabaseBootstrap.clientOrNull()?.auth.currentUser?.id;
  }

  @override
  Future<void> load() async {
    final snapshot = await _store.loadSnapshot();
    _reports = snapshot.reports;
    _isLoaded = true;
    notifyListeners();
    unawaited(_syncAfterLoad(snapshot));
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

    final pushed = await _pushPendingReports(reports);
    await _store.setSyncPending(!pushed);
    if (pushed) {
      await _markReportsSynced(reports);
    }
    return true;
  }

  Future<void> _syncAfterLoad(ContentReportsLocalSnapshot local) async {
    if (_syncInProgress || !_canSync) return;
    _syncInProgress = true;

    try {
      final userId = _userIdProvider();
      if (userId == null) return;

      final remote = await _fetchRemote(userId);
      final merge = ContentReportsSyncCoordinator.merge(
        local: local,
        remote: remote,
      );

      if (merge.changed) {
        await _store.saveReports(merge.reports);
        _reports = merge.reports;
        notifyListeners();
      }

      if (merge.shouldPushLocal) {
        final snapshot = await _store.loadSnapshot();
        final pushed = await _pushPendingReports(snapshot.reports);
        await _store.setSyncPending(!pushed);
        if (pushed) {
          await _markReportsSynced(snapshot.reports);
        }
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Atlas] Synchronisation signalements ignorée: $error');
      }
    } finally {
      _syncInProgress = false;
    }
  }

  Future<List<ContentReport>?> _fetchRemote(String userId) async {
    try {
      return await _remote.fetch(userId).timeout(_syncTimeout);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _pushPendingReports(List<ContentReport> reports) async {
    if (!_canSync) return false;

    final userId = _userIdProvider();
    if (userId == null) return false;

    final pending = reports.where((report) => report.syncPending).toList();
    if (pending.isEmpty) return true;

    try {
      for (final report in pending) {
        await _remote
            .insert(userId: userId, report: report)
            .timeout(_syncTimeout);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _markReportsSynced(List<ContentReport> reports) async {
    final synced = [
      for (final report in reports)
        if (report.syncPending)
          report.copyWith(syncPending: false)
        else
          report,
    ];
    await _store.saveReports(synced);
    _reports = synced;
    notifyListeners();
  }

  bool get _canSync =>
      syncEnabledOverride ||
      (_env.isConfigured &&
          SupabaseBootstrap.isInitialized &&
          _userIdProvider() != null);
}
