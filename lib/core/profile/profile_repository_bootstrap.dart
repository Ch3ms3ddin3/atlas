import '../../features/profile/data/syncing_profile_repository.dart';

/// Point d'entrée par défaut pour le dépôt profil synchronisé.
abstract final class ProfileRepositoryFactory {
  static SyncingProfileRepository createDefault() => SyncingProfileRepository();
}
