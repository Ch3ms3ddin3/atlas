import '../domain/models/user_profile.dart';

/// Profil local et métadonnées de synchronisation.
class ProfileLocalSnapshot {
  const ProfileLocalSnapshot({
    required this.profile,
    this.localUpdatedAt,
    this.syncPending = false,
  });

  final UserProfile profile;
  final DateTime? localUpdatedAt;
  final bool syncPending;

  bool get hasLocalEdits => localUpdatedAt != null;
}
