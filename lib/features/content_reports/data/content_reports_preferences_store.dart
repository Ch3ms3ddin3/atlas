import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/content_report.dart';
import 'content_reports_local_snapshot.dart';

/// Persiste les signalements locaux et les métadonnées de synchronisation.
class ContentReportsPreferencesStore {
  const ContentReportsPreferencesStore();

  static const reportsKey = 'content_reports_json';
  static const syncPendingKey = 'content_reports_sync_pending';

  Future<ContentReportsLocalSnapshot> loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final reports = _decodeReports(prefs.getString(reportsKey));
    return ContentReportsLocalSnapshot(
      reports: reports,
      syncPending: prefs.getBool(syncPendingKey) ?? false,
    );
  }

  Future<void> saveReports(List<ContentReport> reports) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(reports.map((report) => report.toJson()).toList());
    await prefs.setString(reportsKey, encoded);
  }

  Future<void> setSyncPending(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(syncPendingKey, true);
      return;
    }
    await prefs.remove(syncPendingKey);
  }

  static List<ContentReport> _decodeReports(String? raw) {
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>)
            ?ContentReport.fromJson(item),
      ];
    } catch (_) {
      return const [];
    }
  }
}
