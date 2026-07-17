import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/config/atlas_env.dart';
import '../../../core/notifications/notification_preferences_store.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../admission_temporaire/data/at_preferences_store.dart';
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
    @visibleForTesting this.syncEnabledOverride = false,
  })  : _store = store ?? const UserPreferencesStore(),
        _remote = remote ?? const SupabaseUserPreferencesRepository(),
        _prayerStore = prayerStore ?? const NotificationPreferencesStore(),
        _atStore = atStore ?? const AtPreferencesStore(),
        _syncStatusStore = syncStatusStore ?? const CloudSyncStatusStore(),
        _env = env ?? AtlasEnv.fromCompileTime(),
        _userIdProvider = userIdProvider ??
            (() =>
                SupabaseBootstrap.clientOrNull()?.auth.currentUser?.id);

  final UserPreferencesStore _store;
  final SupabaseUserPreferencesRepository _remote;
  final NotificationPreferencesStore _prayerStore;
  final AtPreferencesStore _atStore;
  final CloudSyncStatusStore _syncStatusStore;
  final AtlasEnv _env;
  final String? Function() _userIdProvider;
  @visibleForTesting
  final bool syncEnabledOverride;

  CloudSyncStatus _status = const CloudSyncStatus.idle();
  bool _loaded = false;

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
      final remote = await _remote.fetch(userId);
      final merge = UserPreferencesSyncCoordinator.merge(
        local: local,
        remote: remote,
      );

      if (merge.changed) {
        await _applySnapshot(merge.snapshot);
      }

      if (merge.shouldPush) {
        final pushed = await _remote.upsert(
          userId: userId,
          snapshot: merge.snapshot,
        );
        await _store.setSyncPending(!pushed);
      } else {
        await _store.setSyncPending(false);
      }

      final now = DateTime.now().toUtc();
      await _syncStatusStore.markSynced(now);
      _status = CloudSyncStatus(
        phase: CloudSyncPhase.synced,
        lastSyncedAt: now,
      );
      notifyListeners();
    } catch (_) {
      _status = CloudSyncStatus(
        phase: CloudSyncPhase.error,
        lastSyncedAt: _status.lastSyncedAt,
        errorMessage: 'Synchronisation interrompue',
      );
      notifyListeners();
    }
  }

  Future<void> persistFromUi() async {
    final prayer = await _prayerStore.load();
    final at = await _atStore.loadSnapshot();
    final snapshot = _store.captureFromFilters(
      prayerLeadTime: prayer,
      atNotificationsEnabled: at.notificationsEnabled,
    );
    await _store.save(snapshot);
    await _store.setSyncPending(true);
    unawaited(sync());
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
  }

  bool get _canSync =>
      syncEnabledOverride ||
      (_env.isConfigured && SupabaseBootstrap.isInitialized);
}
