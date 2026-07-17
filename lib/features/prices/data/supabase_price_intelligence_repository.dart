import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/models/price_observation.dart';
import 'price_observation_mapper.dart';

/// Lecture Supabase des observations published + verified (RLS).
class SupabasePriceIntelligenceRepository {
  const SupabasePriceIntelligenceRepository({
    SupabaseClient? Function()? clientProvider,
  }) : _clientProvider = clientProvider ?? SupabaseBootstrap.clientOrNull;

  final SupabaseClient? Function()? _clientProvider;

  Future<List<PriceObservation>> fetchAll() async {
    final client = _clientProvider?.call();
    if (client == null) {
      throw StateError('Client Supabase non initialisé.');
    }

    final rows = await client
        .from('price_observations')
        .select()
        .eq('is_published', true)
        .eq('verification_status', 'verified')
        .order('last_updated_at', ascending: false);

    final items = <PriceObservation>[];
    for (final row in rows as List<dynamic>) {
      if (row is! Map) continue;
      final item = PriceObservationMapper.fromSupabaseRow(
        Map<String, dynamic>.from(row),
      );
      if (item != null) items.add(item);
    }
    return items;
  }
}
