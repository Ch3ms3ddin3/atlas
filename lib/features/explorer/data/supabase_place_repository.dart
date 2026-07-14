import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/models/place_models.dart';
import 'place_record_mapper.dart';

/// Lecture Supabase des lieux publiés.
class SupabasePlaceRepository {
  const SupabasePlaceRepository({
    SupabaseClient? Function()? clientProvider,
  }) : _clientProvider = clientProvider ?? SupabaseBootstrap.clientOrNull;

  final SupabaseClient? Function()? _clientProvider;

  Future<List<PlaceGuide>> fetchAll() async {
    final client = _clientProvider?.call();
    if (client == null) {
      throw StateError('Client Supabase non initialisé.');
    }

    final rows = await client
        .from('places')
        .select()
        .eq('is_published', true)
        .order('name');

    return [
      for (final row in rows)
        PlaceRecordMapper.fromRow(Map<String, dynamic>.from(row)),
    ];
  }
}
