import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/models/procedure_models.dart';
import 'procedure_record_mapper.dart';

/// Lecture Supabase des démarches publiées.
class SupabaseProcedureRepository {
  const SupabaseProcedureRepository({
    SupabaseClient? Function()? clientProvider,
  }) : _clientProvider = clientProvider ?? SupabaseBootstrap.clientOrNull;

  final SupabaseClient? Function()? _clientProvider;

  Future<List<ProcedureGuide>> fetchAll() async {
    final client = _clientProvider?.call();
    if (client == null) {
      throw StateError('Client Supabase non initialisé.');
    }

    final rows = await client
        .from('procedures')
        .select()
        .eq('is_published', true)
        .order('title');

    return [
      for (final row in rows)
        ProcedureRecordMapper.fromRow(Map<String, dynamic>.from(row)),
    ];
  }
}
