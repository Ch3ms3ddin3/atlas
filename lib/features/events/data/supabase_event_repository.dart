import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/editorial/editorial_remote_catalog.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/models/atlas_event.dart';
import 'event_record_mapper.dart';

/// Lecture Supabase des événements publiés.
class SupabaseEventRepository implements EditorialRemoteCatalog<AtlasEvent> {
  const SupabaseEventRepository({
    SupabaseClient? Function()? clientProvider,
  }) : _clientProvider = clientProvider ?? SupabaseBootstrap.clientOrNull;

  final SupabaseClient? Function()? _clientProvider;

  @override
  Future<List<AtlasEvent>> fetchAll() async {
    final client = _clientProvider?.call();
    if (client == null) {
      throw StateError('Client Supabase non initialisé.');
    }

    final rows = await client
        .from('events')
        .select()
        .eq('is_published', true)
        .order('start_at');

    return [
      for (final row in rows)
        ?EventRecordMapper.tryFromRow(Map<String, dynamic>.from(row)),
    ];
  }
}
