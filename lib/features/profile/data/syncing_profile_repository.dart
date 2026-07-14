import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/config/atlas_env.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
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
    Duration? syncTimeout,
    @visibleForTesting this.syncEnabledOverride = false,
  })  : _store = store ?? const ProfilePreferencesStore(),
        _remote = remote ?? const SupabaseProfileRepository(),
        _env = env ?? AtlasEnv.fromCompileTime(),
        _userIdProvider = userIdProvider ?? _defaultUserId,
        _syncTimeout = syncTimeout ?? const Duration(seconds: 5),
        super.base();

  final ProfilePreferencesStore _store;
  final SupabaseProfileRepository _remote;
  final AtlasEnv _env;
  final String? Function() _userIdProvider;
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

  @override
  Future<void> load() async {
    final snapshot = await _store.loadSnapshot();
    _profile = snapshot.profile;
    _isLoaded = true;
    notifyListeners();
    unawaited(_syncAfterLoad(snapshot));
  }

  @override
  Future<bool> save(UserProfile candidate) async {
    final sanitized = _sanitize(candidate);
    if (sanitized == null) return false;

    final now = DateTime.now().toUtc();
    await _store.saveProfile(sanitized, localUpdatedAt: now);
    _profile = sanitized;
    notifyListeners();

    final pushed = await _pushProfile(sanitized);
    await _store.setSyncPending(!pushed);
    return true;
  }

  Future<void> _syncAfterLoad(ProfileLocalSnapshot local) async {
    if (_syncInProgress || !_canSync) return;
    _syncInProgress = true;

    try {
      final userId = _userIdProvider();
      if (userId == null) return;

      final remote = await _fetchRemote(userId);
      final merge = ProfileSyncCoordinator.merge(local: local, remote: remote);

      var profile = local.profile;

      if (merge.changed) {
        final localUpdatedAt = _resolvedLocalUpdatedAt(
          local: local,
          remote: remote,
        );
        await _store.saveProfile(merge.profile, localUpdatedAt: localUpdatedAt);
        profile = merge.profile;
        _profile = merge.profile;
        notifyListeners();
      }

      if (local.syncPending || merge.shouldPushLocal) {
        final pushed = await _pushProfile(profile);
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

  Future<bool> _pushProfile(UserProfile profile) async {
    if (!_canSync) return false;

    final userId = _userIdProvider();
    if (userId == null) return false;

    try {
      await _remote
          .upsert(userId: userId, profile: profile)
          .timeout(_syncTimeout);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool get _canSync =>
      syncEnabledOverride ||
      (_env.isConfigured &&
          SupabaseBootstrap.isInitialized &&
          _userIdProvider() != null);

  UserProfile? _sanitize(UserProfile candidate) {
    final sanitized = UserProfile(
      firstName: ProfileValidator.sanitizeFirstName(candidate.firstName),
      preferredCity:
          ProfileValidator.sanitizePreferredCity(candidate.preferredCity),
      language: candidate.language,
      userType: candidate.userType,
    );

    if (!ProfileValidator.isFormValid(
      firstName: sanitized.firstName,
      preferredCity: sanitized.preferredCity,
    )) {
      return null;
    }
    return sanitized;
  }
}
