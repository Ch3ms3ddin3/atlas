import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/models/favorite_record.dart';
import 'favorite_record_mapper.dart';

/// Accès Supabase à la table `favorites` (lecture + upsert soft-delete).
class SupabaseFavoritesRepository {
  const SupabaseFavoritesRepository({
    SupabaseClient? Function()? clientProvider,
  }) : _clientProvider = clientProvider ?? SupabaseBootstrap.clientOrNull;

  final SupabaseClient? Function()? _clientProvider;

  /// Charge toutes les lignes de l'utilisateur, y compris les tombstones.
  Future<List<FavoriteRecord>> fetch(String userId) async {
    final client = _clientProvider?.call();
    if (client == null) {
      throw StateError('Client Supabase non initialisé.');
    }

    final rows = await client
        .from('favorites')
        .select()
        .eq('user_id', userId);

    return [
      for (final row in rows)
        FavoriteRecordMapper.fromRow(Map<String, dynamic>.from(row)),
    ];
  }

  /// Insert ou met à jour sur `(user_id, entity_type, entity_slug)`.
  Future<void> upsert({
    required String userId,
    required FavoriteRecord record,
  }) async {
    final client = _clientProvider?.call();
    if (client == null) {
      throw StateError('Client Supabase non initialisé.');
    }

    await client.from('favorites').upsert(
          FavoriteRecordMapper.toRow(userId: userId, record: record),
          onConflict: 'user_id,entity_type,entity_slug',
        );
  }
}
