/// Helpers to abort in-flight sync/persist when the auth identity changes.
///
/// Syncing repositories capture [userId] before an `await`, then must call
/// [isStillCurrent] before applying remote data locally or pushing to cloud.
abstract final class AuthSyncIdentity {
  /// True when [userIdProvider] still returns the same id that started the op.
  static bool isStillCurrent({
    required String? capturedUserId,
    required String? Function() userIdProvider,
  }) {
    return capturedUserId == userIdProvider();
  }
}
