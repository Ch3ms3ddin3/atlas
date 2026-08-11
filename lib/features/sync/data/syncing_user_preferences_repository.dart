import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/config/atlas_env.dart';
import '../../../core/notifications/notification_preferences_store.dart';
import '../../../core/notifications/prayer_notification_bootstrap.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../admission_temporaire/data/at_preferences_store.dart';
import '../../auth/data/auth_sync_identity.dart';
import '../../explorer/domain/place_browse_filters.dart';
import '../domain/cloud_sync_status.dart';
import 'supabase_user_preferences_repository.dart';
import 'user_preferences_store.dart';
import 'user_preferences_sync_coordinator.dart';

/// Orchestre la sync des préférences + horodatage global.
class SyncingUserPreferencesRepository extends ChangeNotifier {
  SyncingUserPreferencesRepository({
    UserPreferencesStore? store,
    SupabaseUserPreferencesRepository? remote,
    NotificationPreferencesStore? prayerStore,
    AtPreferencesStore? atStore,
    CloudSyncStatusStore? syncStatusStore,
    AtlasEnv? env,
    String? Function()? userIdProvider,
    bool Function()? isSignedInProvider,
    @visibleForTesting this.syncEnabledOverride = false,
  })  : _store = store ?? const UserPreferencesStore(),
        _remote = remote ?? const SupabaseUserPreferencesRepository(),
        _prayerStore = prayerStore ?? const NotificationPreferencesStore(),
        _atStore = atStore ?? const AtPreferencesStore(),
        _syncStatusStore = syncStatusStore ?? const CloudSyncStatusStore(),
        _env = env ?? AtlasEnv.fromCompileTime(),
        _userIdProvider = userIdProvider ??
            (() =>
                SupabaseBootstrap.clientOrNull()?.auth.currentUser?.id),
        _isSignedInProvider = isSignedInProvider ?? _defaultIsSignedIn;

  final UserPreferencesStore _store;
  final SupabaseUserPreferencesRepository _remote;
  final NotificationPreferencesStore _prayerStore;
  final AtPreferencesStore _atStore;
  final CloudSyncStatusStore _syncStatusStore;
  final AtlasEnv _env;
  final String? Function() _userIdProvider;
  final bool Function() _isSignedInProvider;
  @visibleForTesting
  final bool syncEnabledOverride;

  CloudSyncStatus _status = const CloudSyncStatus.idle();
  bool _loaded = false;
  bool _syncInProgress = false;
  bool _syncQueued = false;

  static bool _defaultIsSignedIn() => SupabaseBootstrap.isSignedInUser;

  CloudSyncStatus get status => _status;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final snapshot = await _composeLocalSnapshot();
    _store.applyExplorerFilters(snapshot);
    final last = await _syncStatusStore.loadLastSyncedAt();
    _status = CloudSyncStatus(
      phase: _canSync ? CloudSyncPhase.idle : CloudSyncPhase.offline,
      lastSyncedAt: last,
    );
    _loaded = true;
    notifyListeners();
    unawaited(sync());
  }

  Future<void> sync() async {
    if (_syncInProgress) {
      _syncQueued = true;
      return;
    }
    _syncInProgress = true;
    try {
      do {
        _syncQueued = false;
        await _syncOnce();
      } while (_syncQueued);
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> _syncOnce() async {
    if (!_canSync) {
      _status = CloudSyncStatus(
        phase: CloudSyncPhase.offline,
        lastSyncedAt: _status.lastSyncedAt,
      );
      notifyListeners();
      return;
    }

    final userId = _userIdProvider();
    if (userId == null) return;

    _status = CloudSyncStatus(
      phase: CloudSyncPhase.syncing,
      lastSyncedAt: _status.lastSyncedAt,
    );
    notifyListeners();

    try {
      final local = await _composeLocalSnapshot();
      if (!AuthSyncIdentity.isStillCurrent(
        capturedUserId: userId,
        userIdProvider: _userIdProvider,
      )) {
        return;
      }
      final remote = await _remote.fetch(userId);
      if (!AuthSyncIdentity.isStillCurrent(
        capturedUserId: userId,
        userIdProvider: _userIdProvider,
      )) {
        return;
      }
      final merge = UserPreferencesSyncCoordinator.merge(
        local: local,
        remote: remote,
      );

      if (merge.changed) {
        await _applySnapshot(merge.snapshot);
        if (!AuthSyncIdentity.isStillCurrent(
          capturedUserId: userId,
          userIdProvider: _userIdProvider,
        )) {
          return;
        }
      }

      if (merge.shouldPush) {
        if (!AuthSyncIdentity.isStillCurrent(
          capturedUserId: userId,
          userIdProvider: _userIdProvider,
        )) {
          return;
        }
        final pushed = await _remote.upsert(
          userId: userId,
          snapshot: merge.snapshot,
        );
        if (!AuthSyncIdentity.isStillCurrent(
          capturedUserId: userId,
          userIdProvider: _userIdProvider,
        )) {
          return;
        }
        await _store.setSyncPending(!pushed);
      } else {
        await _store.setSyncPending(false);
      }

      final now = DateTime.now().toUtc();
      await _syncStatusStore.markSynced(now);
      if (!AuthSyncIdentity.isStillCurrent(
        capturedUserId: userId,
        userIdProvider: _userIdProvider,
      )) {
        return;
      }
      _status = CloudSyncStatus(
        phase: CloudSyncPhase.synced,
        lastSyncedAt: now,
      );
      notifyListeners();
    } catch (_) {
      if (!AuthSyncIdentity.isStillCurrent(
        capturedUserId: userId,
        userIdProvider: _userIdProvider,
      )) {
        return;
      }
      _status = CloudSyncStatus(
        phase: CloudSyncPhase.error,
        lastSyncedAt: _status.lastSyncedAt,
        errorMessage: 'Synchronisation interrompue',
      );
      notifyListeners();
    }
  }

  /// Persists UI prefs and optionally waits for the cloud round-trip.
  ///
  /// Prayer lead-time changes must [awaitSync] so a quick sign-out cannot
  /// clear local state before the upsert lands on Supabase.
  Future<void> persistFromUi({bool awaitSync = false}) async {
    final userIdAtStart = _userIdProvider();
    final prayer = await _prayerStore.load();
    final at = await _atStore.loadSnapshot();
    final snapshot = _store.captureFromFilters(
      prayerLeadTime: prayer,
      atNotificationsEnabled: at.notificationsEnabled,
    );
    await _store.save(snapshot);
    await _store.setSyncPending(true);
    if (!AuthSyncIdentity.isStillCurrent(
      capturedUserId: userIdAtStart,
      userIdProvider: _userIdProvider,
    )) {
      return;
    }
    if (awaitSync) {
      await sync();
    } else {
      unawaited(sync());
    }
  }

  Future<UserPreferencesSnapshot> _composeLocalSnapshot() async {
    final stored = await _store.load();
    final prayer = await _prayerStore.load();
    final at = await _atStore.loadSnapshot();
    final filters = PlaceBrowseFilters.instance;
    return UserPreferencesSnapshot(
      prayerLeadTime: prayer,
      atNotificationsEnabled: at.notificationsEnabled,
      explorerCity: filters.cityName.isNotEmpty
          ? filters.cityName
          : stored.explorerCity,
      explorerCategory: filters.category ?? stored.explorerCategory,
      explorerFavoritesOnly: filters.favoritesOnly,
      localUpdatedAt: stored.localUpdatedAt,
      syncPending: stored.syncPending,
    );
  }

  Future<void> _applySnapshot(UserPreferencesSnapshot snapshot) async {
    await _store.save(snapshot);
    await _prayerStore.save(snapshot.prayerLeadTime);
    await _atStore.setNotificationsEnabled(snapshot.atNotificationsEnabled);
    _store.applyExplorerFilters(snapshot);
    // Keep OS prayer schedules aligned with the effective preference.
    unawaited(prayerNotificationCoordinator.sync(force: true));
  }

  bool get _canSync =>
      syncEnabledOverride ||
      (_env.isConfigured &&
          SupabaseBootstrap.isInitialized &&
          _userIdProvider() != null &&
          _isSignedInProvider());
}
