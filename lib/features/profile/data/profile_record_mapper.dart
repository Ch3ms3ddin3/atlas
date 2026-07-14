import '../domain/models/user_profile.dart';
import 'profile_remote_snapshot.dart';

/// Convertit les lignes Supabase vers les modèles profil.
abstract final class ProfileRecordMapper {
  static ProfileRemoteSnapshot fromRow(Map<String, dynamic> row) {
    final profile = UserProfile(
      firstName: row['first_name'] as String,
      preferredCity: row['preferred_city'] as String,
      language: AtlasLanguageLabels.fromStorage(row['language'] as String?),
      userType: AtlasUserTypeLabels.fromStorage(row['user_type'] as String?),
    );

    return ProfileRemoteSnapshot(
      profile: profile,
      updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
    );
  }

  static Map<String, dynamic> toRow({
    required String userId,
    required UserProfile profile,
  }) {
    return {
      'id': userId,
      'first_name': profile.firstName,
      'preferred_city': profile.preferredCity,
      'language': profile.language.name,
      'user_type': profile.userType.name,
    };
  }
}
