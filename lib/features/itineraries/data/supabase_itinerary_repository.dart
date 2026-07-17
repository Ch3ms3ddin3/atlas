import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/models/trip.dart';

/// Lecture / écriture Supabase des voyages (payload JSON).
class SupabaseItineraryRepository {
  const SupabaseItineraryRepository();

  Future<List<Trip>> fetchAll(String userId) async {
    final client = SupabaseBootstrap.clientOrNull();
    if (client == null) return const [];
    final rows = await client
        .from('trips')
        .select('payload')
        .eq('user_id', userId);
    final list = rows as List<dynamic>;
    return [
      for (final row in list)
        if (row is Map<String, dynamic> && row['payload'] is Map)
          Trip.fromJson(
            Map<String, dynamic>.from(row['payload'] as Map),
          ),
    ];
  }

  Future<void> upsertAll(String userId, List<Trip> trips) async {
    final client = SupabaseBootstrap.clientOrNull();
    if (client == null) return;
    final active = trips.where((t) => t.isActive).toList();
    final rows = [
      for (final trip in active)
        {
          'id': trip.id,
          'user_id': userId,
          'payload': trip.copyWith(syncPending: false).toJson(),
          'updated_at': trip.updatedAt.toUtc().toIso8601String(),
          'is_active': true,
        },
    ];
    if (rows.isNotEmpty) {
      await client.from('trips').upsert(rows);
    }

    final deleted = trips.where((t) => !t.isActive).toList();
    for (final trip in deleted) {
      await client.from('trips').upsert({
        'id': trip.id,
        'user_id': userId,
        'payload': trip.copyWith(syncPending: false).toJson(),
        'updated_at': trip.updatedAt.toUtc().toIso8601String(),
        'is_active': false,
      });
    }
  }
}
