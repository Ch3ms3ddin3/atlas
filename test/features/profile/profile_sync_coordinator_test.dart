import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/profile/data/profile_local_snapshot.dart';
import 'package:atlas/features/profile/data/profile_remote_snapshot.dart';
import 'package:atlas/features/profile/data/profile_sync_coordinator.dart';
import 'package:atlas/features/profile/domain/models/user_profile.dart';

void main() {
  const localProfile = UserProfile(
    firstName: 'Salma',
    preferredCity: 'Casablanca',
    language: AtlasLanguage.french,
    userType: AtlasUserType.resident,
  );

  const remoteProfile = UserProfile(
    firstName: 'Yasmine',
    preferredCity: 'Rabat',
    language: AtlasLanguage.english,
    userType: AtlasUserType.mre,
  );

  final localEditedAt = DateTime.utc(2026, 7, 10, 12);
  final remoteEditedAt = DateTime.utc(2026, 7, 12, 12);

  group('ProfileSyncCoordinator', () {
    test('conserve le local quand le distant est absent', () {
      final result = ProfileSyncCoordinator.merge(
        local: ProfileLocalSnapshot(
          profile: localProfile,
          localUpdatedAt: localEditedAt,
        ),
      );

      expect(result.profile, localProfile);
      expect(result.changed, isFalse);
      expect(result.shouldPushLocal, isTrue);
    });

    test('applique le distant sans édition locale', () {
      final result = ProfileSyncCoordinator.merge(
        local: const ProfileLocalSnapshot(profile: UserProfile.defaults),
        remote: ProfileRemoteSnapshot(
          profile: remoteProfile,
          updatedAt: remoteEditedAt,
        ),
      );

      expect(result.profile, remoteProfile);
      expect(result.changed, isTrue);
      expect(result.shouldPushLocal, isFalse);
    });

    test('conserve le local quand il est plus récent', () {
      final result = ProfileSyncCoordinator.merge(
        local: ProfileLocalSnapshot(
          profile: localProfile,
          localUpdatedAt: remoteEditedAt.add(const Duration(hours: 1)),
        ),
        remote: ProfileRemoteSnapshot(
          profile: remoteProfile,
          updatedAt: remoteEditedAt,
        ),
      );

      expect(result.profile, localProfile);
      expect(result.changed, isFalse);
      expect(result.shouldPushLocal, isTrue);
    });

    test('applique le distant quand il est plus récent', () {
      final result = ProfileSyncCoordinator.merge(
        local: ProfileLocalSnapshot(
          profile: localProfile,
          localUpdatedAt: localEditedAt,
        ),
        remote: ProfileRemoteSnapshot(
          profile: remoteProfile,
          updatedAt: remoteEditedAt,
        ),
      );

      expect(result.profile, remoteProfile);
      expect(result.changed, isTrue);
      expect(result.shouldPushLocal, isFalse);
    });

    test('le local l emporte à timestamps égaux', () {
      final result = ProfileSyncCoordinator.merge(
        local: ProfileLocalSnapshot(
          profile: localProfile,
          localUpdatedAt: remoteEditedAt,
        ),
        remote: ProfileRemoteSnapshot(
          profile: remoteProfile,
          updatedAt: remoteEditedAt,
        ),
      );

      expect(result.profile, localProfile);
      expect(result.changed, isFalse);
      expect(result.shouldPushLocal, isTrue);
    });
  });
}
