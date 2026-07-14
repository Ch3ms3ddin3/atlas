import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/models/user_profile.dart';
import 'profile_record_mapper.dart';
import 'profile_remote_snapshot.dart';

/// Lecture et écriture Supabase du profil utilisateur.
class SupabaseProfileRepository {
  const SupabaseProfileRepository({
    SupabaseClient? Function()? clientProvider,
  }) : _clientProvider = clientProvider ?? SupabaseBootstrap.clientOrNull;

  final SupabaseClient? Function()? _clientProvider;

  Future<ProfileRemoteSnapshot?> fetch(String userId) async {
    final client = _clientProvider?.call();
    if (client == null) {
      throw StateError('Client Supabase non initialisé.');
    }

    final row = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (row == null) return null;
    return ProfileRecordMapper.fromRow(Map<String, dynamic>.from(row));
  }

  Future<void> upsert({
    required String userId,
    required UserProfile profile,
  }) async {
    final client = _clientProvider?.call();
    if (client == null) {
      throw StateError('Client Supabase non initialisé.');
    }

    await client.from('profiles').upsert(
          ProfileRecordMapper.toRow(userId: userId, profile: profile),
        );
  }
}
