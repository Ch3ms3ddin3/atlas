import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/config/atlas_env.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/at_repository.dart';
import '../domain/models/at_vehicle.dart';
import 'at_preferences_store.dart';
import 'at_sync_coordinator.dart';
import 'local_at_repository.dart';
import 'supabase_at_repository.dart';

/// AT local-first avec synchronisation Supabase silencieuse.
class SyncingAtRepository extends AtRepository {
  SyncingAtRepository({
    LocalAtRepository? local,
    AtPreferencesStore? store,
    SupabaseAtRepository? remote,
    AtlasEnv? env,
    String? Function()? userIdProvider,
    @visibleForTesting this.syncEnabledOverride = false,
  })  : _local = local ?? LocalAtRepository(store: store),
        _store = store ?? const AtPreferencesStore(),
        _remote = remote ?? const SupabaseAtRepository(),
        _env = env ?? AtlasEnv.fromCompileTime(),
        _userIdProvider = userIdProvider ??
            (() =>
                SupabaseBootstrap.clientOrNull()?.auth.currentUser?.id),
        super.base() {
    _local.addListener(notifyListeners);
  }

  final LocalAtRepository _local;
  final AtPreferencesStore _store;
  final SupabaseAtRepository _remote;
  final AtlasEnv _env;
  final String? Function() _userIdProvider;
  @visibleForTesting
  final bool syncEnabledOverride;

  bool _syncInProgress = false;

  @override
  bool get isLoaded => _local.isLoaded;

  @override
  List<AtVehicle> get vehicles => _local.vehicles;

  @override
  List<AtVehicle> get activeVehicles => _local.activeVehicles;

  @override
  bool get notificationsEnabled => _local.notificationsEnabled;

  @override
  bool get notificationPromptShown => _local.notificationPromptShown;

  @override
  Future<void> load() async {
    await _local.load();
    unawaited(_sync());
  }

  @override
  Future<bool> addVehicle(AtVehicle vehicle) async {
    final ok = await _local.addVehicle(vehicle);
    if (ok) {
      await _store.setSyncPending(true);
      unawaited(_sync());
    }
    return ok;
  }

  @override
  Future<bool> updateVehicle(AtVehicle vehicle) async {
    final ok = await _local.updateVehicle(vehicle);
    if (ok) {
      await _store.setSyncPending(true);
      unawaited(_sync());
    }
    return ok;
  }

  @override
  Future<bool> deleteVehicle(String id) async {
    final ok = await _local.deleteVehicle(id);
    if (ok) {
      await _store.setSyncPending(true);
      unawaited(_sync());
    }
    return ok;
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) {
    return _local.setNotificationsEnabled(enabled);
  }

  @override
  Future<void> markNotificationPromptShown() {
    return _local.markNotificationPromptShown();
  }

  Future<void> _sync() async {
    if (_syncInProgress || !_canSync) return;
    _syncInProgress = true;
    try {
      final userId = _userIdProvider();
      if (userId == null) return;

      final local = await _store.loadSnapshot();
      final remote = await _remote.fetchAll(userId);
      final merged = AtSyncCoordinator.merge(local: local, remote: remote);

      if (!_vehiclesEqual(local.vehicles, merged.vehicles)) {
        await _store.saveVehicles(merged.vehicles);
        await _local.load();
      }

      final pushed = await _remote.upsertAll(
        userId: userId,
        vehicles: merged.vehicles,
      );
      await _store.setSyncPending(!pushed);
    } finally {
      _syncInProgress = false;
    }
  }

  bool get _canSync =>
      syncEnabledOverride ||
      (_env.isConfigured && SupabaseBootstrap.isInitialized);

  static bool _vehiclesEqual(List<AtVehicle> a, List<AtVehicle> b) {
    if (a.length != b.length) return false;
    final mapB = {for (final v in b) v.id: v};
    for (final v in a) {
      final other = mapB[v.id];
      if (other == null ||
          other.updatedAt != v.updatedAt ||
          other.isActive != v.isActive) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _local.removeListener(notifyListeners);
    _local.dispose();
    super.dispose();
  }
}
