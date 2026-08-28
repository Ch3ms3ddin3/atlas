import '../domain/models/user_profile.dart';
import 'profile_local_snapshot.dart';
import 'profile_remote_snapshot.dart';
import 'profile_validator.dart';

/// Résultat de fusion local / distant.
class ProfileMergeResult {
  const ProfileMergeResult({
    required this.profile,
    required this.changed,
    required this.shouldPushLocal,
  });

  final UserProfile profile;
  final bool changed;
  final bool shouldPushLocal;
}

/// Applique les règles de conflit entre profil local et distant.
abstract final class ProfileSyncCoordinator {
  static ProfileMergeResult merge({
    required ProfileLocalSnapshot local,
    ProfileRemoteSnapshot? remote,
  }) {
    if (remote == null) {
      return ProfileMergeResult(
        profile: local.profile,
        changed: false,
        shouldPushLocal: local.hasLocalEdits,
      );
    }

    if (!local.hasLocalEdits) {
      if (!_isValid(remote.profile)) {
        return ProfileMergeResult(
          profile: local.profile,
          changed: false,
          shouldPushLocal: false,
        );
      }
      final adopted = _adoptRemote(local.profile, remote.profile);
      return ProfileMergeResult(
        profile: adopted,
        changed: !_profilesEqual(local.profile, adopted),
        shouldPushLocal: false,
      );
    }

    final localUpdatedAt = local.localUpdatedAt!.toUtc();
    final remoteUpdatedAt = remote.updatedAt.toUtc();

    // Pending local writes must not be overwritten by a stale/newer remote,
    // even if the server clock is ahead (align with UserPreferencesSyncCoordinator).
    if (local.syncPending) {
      return ProfileMergeResult(
        profile: local.profile,
        changed: false,
        shouldPushLocal: true,
      );
    }

    if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
      return ProfileMergeResult(
        profile: local.profile,
        changed: false,
        shouldPushLocal: true,
      );
    }

    if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
      if (!_isValid(remote.profile)) {
        return ProfileMergeResult(
          profile: local.profile,
          changed: false,
          shouldPushLocal: true,
        );
      }
      final adopted = _adoptRemote(local.profile, remote.profile);
      return ProfileMergeResult(
        profile: adopted,
        changed: !_profilesEqual(local.profile, adopted),
        shouldPushLocal: false,
      );
    }

    // Timestamps égaux — le local l'emporte.
    return ProfileMergeResult(
      profile: local.profile,
      changed: false,
      shouldPushLocal: true,
    );
  }

  static bool _isValid(UserProfile profile) {
    return ProfileValidator.isFormValid(
      firstName: profile.firstName,
      preferredCity: profile.preferredCity,
    );
  }

  static bool _profilesEqual(UserProfile a, UserProfile b) {
    return a.firstName == b.firstName &&
        a.preferredCity == b.preferredCity &&
        a.citySource == b.citySource &&
        a.language == b.language &&
        a.userType == b.userType &&
        a.displayName == b.displayName &&
        a.avatarUrl == b.avatarUrl;
  }

  /// `citySource` est local : on le conserve si la ville distante est identique.
  static UserProfile _adoptRemote(UserProfile local, UserProfile remote) {
    if (local.preferredCity == remote.preferredCity &&
        local.citySource != remote.citySource) {
      return remote.copyWith(citySource: local.citySource);
    }
    return remote;
  }
}
