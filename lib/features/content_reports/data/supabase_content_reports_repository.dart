import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/models/content_report.dart';
import 'content_report_record_mapper.dart';

/// Lecture et insertion Supabase des signalements.
class SupabaseContentReportsRepository {
  const SupabaseContentReportsRepository({
    SupabaseClient? Function()? clientProvider,
  }) : _clientProvider = clientProvider ?? SupabaseBootstrap.clientOrNull;

  final SupabaseClient? Function()? _clientProvider;

  Future<List<ContentReport>> fetch(String userId) async {
    final client = _clientProvider?.call();
    if (client == null) {
      throw StateError('Client Supabase non initialisé.');
    }

    final rows = await client
        .from('content_reports')
        .select()
        .eq('user_id', userId)
        .order('created_at');

    return [
      for (final row in rows)
        ContentReportRecordMapper.fromRow(Map<String, dynamic>.from(row)),
    ];
  }

  Future<void> insert({
    required String userId,
    required ContentReport report,
  }) async {
    final client = _clientProvider?.call();
    if (client == null) {
      throw StateError('Client Supabase non initialisé.');
    }

    try {
      await client.from('content_reports').insert(
            ContentReportRecordMapper.toInsertRow(
              userId: userId,
              report: report,
            ),
          );
    } on PostgrestException catch (error) {
      // Retry silencieux si le signalement a déjà été inséré.
      if (error.code == '23505') return;
      rethrow;
    }
  }
}
