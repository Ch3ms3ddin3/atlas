import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/models/price_models.dart';
import 'price_record_mapper.dart';

/// Lecture Supabase des repères de prix publiés.
class SupabasePriceRepository {
  const SupabasePriceRepository({
    SupabaseClient? Function()? clientProvider,
  }) : _clientProvider = clientProvider ?? SupabaseBootstrap.clientOrNull;

  final SupabaseClient? Function()? _clientProvider;

  Future<List<PriceGuide>> fetchAll() async {
    final client = _clientProvider?.call();
    if (client == null) {
      throw StateError('Client Supabase non initialisé.');
    }

    final rows = await client
        .from('prices')
        .select()
        .eq('is_published', true)
        .order('name');

    return [
      for (final row in rows)
        PriceRecordMapper.fromRow(Map<String, dynamic>.from(row)),
    ];
  }
}
