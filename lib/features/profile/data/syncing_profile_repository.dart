import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/config/atlas_env.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../auth/data/auth_sync_identity.dart';
import '../domain/models/user_profile.dart';
import '../domain/profile_repository.dart';
import 'profile_local_snapshot.dart';
import 'profile_preferences_store.dart';
import 'profile_remote_snapshot.dart';
import 'profile_sync_coordinator.dart';
import 'profile_validator.dart';
import 'supabase_profile_repository.dart';

/// Profil local d'abord, synchronisation Supabase silencieuse en arrière-plan.
class SyncingProfileRepository extends ProfileRepository {
  SyncingProfileRepository({
    ProfilePreferencesStore? store,
    SupabaseProfileRepository? remote,
    AtlasEnv? env,
    String? Function()? userIdProvider,
    bool Function()? isSignedInProvider,
    Duration? syncTimeout,
    @visibleForTesting this.syncEnabledOverride = false,
  }) : _store = store ?? const ProfilePreferencesStore(),
       _remote = remote ?? const SupabaseProfileRepository(),
       _env = env ?? AtlasEnv.fromCompileTime(),
       _userIdProvider = userIdProvider ?? _defaultUserId,
       _isSignedInProvider = isSignedInProvider ?? _defaultIsSignedIn,
       _syncTimeout = syncTimeout ?? const Duration(seconds: 5),
       super.base();

  final ProfilePreferencesStore _store;
  final SupabaseProfileRepository _remote;
  final AtlasEnv _env;
  final String? Function() _userIdProvider;
  final bool Function() _isSignedInProvider;
  final Duration _syncTimeout;
  @visibleForTesting
  final bool syncEnabledOverride;

  UserProfile _profile = UserProfile.defaults;
  bool _isLoaded = false;
  bool _syncInProgress = false;

  @override
  UserProfile get profile => _profile;

  @override
  bool get isLoaded => _isLoaded;

  static String? _defaultUserId() {
    return SupabaseBootstrap.clientOrNull()?.auth.currentUser?.id;
  }

  static bool _defaultIsSignedIn() => SupabaseBootstrap.isSignedInUser;

  @override
  Future<void> load() async {
    final snapshot = await _store.loadSnapshot();
    _profile = snapshot.profile;
    _isLoaded = true;
    notifyListeners();
    unawaited(_syncAfterLoad());
  }

  @override
  Future<bool> save(UserProfile candidate) async {
    final sanitized = ProfileValidator.sanitizeForSave(candidate);
    if (sanitized == null) return false;

    final userIdAtStart = _userIdProvider();
    final now = DateTime.now().toUtc();
    await _store.saveProfile(sanitized, localUpdatedAt: now);
    _profile = sanitized;
    notifyListeners();

    final pushed = await _pushProfile(
      sanitized,
      expectedUserId: userIdAtStart,
    );
    if (!AuthSyncIdentity.isStillCurrent(
      capturedUserId: userIdAtStart,
      userIdProvider: _userIdProvider,
    )) {
      // Identity flipped mid-save — leave syncPending for the *new* session
      // only if local still holds this write; boundary clear resets stores.
      return true;
    }
    await _store.setSyncPending(!pushed);
    return true;
  }

  Future<void> _syncAfterLoad() async {
    if (_syncInProgress || !_canSync) return;
    _syncInProgress = true;

    try {
      final userId = _userIdProvider();
      if (userId == null) return;

      final remote = await _fetchRemote(userId);
      if (!AuthSyncIdentity.isStillCurrent(
        capturedUserId: userId,
        userIdProvider: _userIdProvider,
      )) {
        return;
      }
      // Re-read after the network round-trip. A concurrent [save] can land
      // while fetch is in flight; merging/pushing the load-time snapshot would
      // overwrite a newer preferredCity (and other fields) on remote, then
      // lose them on the next cold start when remote wins by timestamp.
      final latestLocal = await _store.loadSnapshot();
      if (!AuthSyncIdentity.isStillCurrent(
        capturedUserId: userId,
        userIdProvider: _userIdProvider,
      )) {
        return;
      }
      final merge = ProfileSyncCoordinator.merge(
        local: latestLocal,
        remote: remote,
      );

      var profile = latestLocal.profile;

      if (merge.changed) {
        final localUpdatedAt = _resolvedLocalUpdatedAt(
          local: latestLocal,
          remote: remote,
        );
        await _store.saveProfile(merge.profile, localUpdatedAt: localUpdatedAt);
        if (!AuthSyncIdentity.isStillCurrent(
          capturedUserId: userId,
          userIdProvider: _userIdProvider,
        )) {
          return;
        }
        profile = merge.profile;
        _profile = merge.profile;
        notifyListeners();
      }

      if (latestLocal.syncPending || merge.shouldPushLocal) {
        final pushed = await _pushProfile(profile, expectedUserId: userId);
        if (!AuthSyncIdentity.isStillCurrent(
          capturedUserId: userId,
          userIdProvider: _userIdProvider,
        )) {
          return;
        }
        await _store.setSyncPending(!pushed);
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Atlas] Synchronisation profil ignorée: $error');
      }
    } finally {
      _syncInProgress = false;
    }
  }

  DateTime _resolvedLocalUpdatedAt({
    required ProfileLocalSnapshot local,
    required ProfileRemoteSnapshot? remote,
  }) {
    if (local.hasLocalEdits) {
      return local.localUpdatedAt!.toUtc();
    }
    return remote?.updatedAt.toUtc() ?? DateTime.now().toUtc();
  }

  Future<ProfileRemoteSnapshot?> _fetchRemote(String userId) async {
    try {
      return await _remote.fetch(userId).timeout(_syncTimeout);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _pushProfile(
    UserProfile profile, {
    String? expectedUserId,
  }) async {
    if (!_canSync) return false;

    final userId = _userIdProvider();
    if (userId == null) return false;
    if (expectedUserId != null && userId != expectedUserId) return false;

    try {
      await _remote
          .upsert(userId: userId, profile: profile)
          .timeout(_syncTimeout);
      return AuthSyncIdentity.isStillCurrent(
        capturedUserId: expectedUserId ?? userId,
        userIdProvider: _userIdProvider,
      );
    } catch (_) {
      return false;
    }
  }

  bool get _canSync =>
      syncEnabledOverride ||
      (_env.isConfigured &&
          SupabaseBootstrap.isInitialized &&
          _userIdProvider() != null &&
          _isSignedInProvider());
}
