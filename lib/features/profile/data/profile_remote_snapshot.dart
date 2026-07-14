import '../domain/models/user_profile.dart';

/// Profil distant avec horodatage serveur.
class ProfileRemoteSnapshot {
  const ProfileRemoteSnapshot({
    required this.profile,
    required this.updatedAt,
  });

  final UserProfile profile;
  final DateTime updatedAt;
}
