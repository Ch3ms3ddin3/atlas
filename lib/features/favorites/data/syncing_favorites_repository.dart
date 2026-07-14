import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/config/atlas_env.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/favorite_entity_type.dart';
import '../domain/favorites_repository.dart';
import '../domain/models/favorite_key.dart';
import '../domain/models/favorite_record.dart';
import 'favorite_validator.dart';
import 'favorites_local_snapshot.dart';
import 'favorites_preferences_store.dart';
import 'favorites_sync_coordinator.dart';
import 'supabase_favorites_repository.dart';

/// Favoris local d'abord, synchronisation Supabase silencieuse en arrière-plan.
class SyncingFavoritesRepository extends FavoritesRepository {
  SyncingFavoritesRepository({
    FavoritesPreferencesStore? store,
    SupabaseFavoritesRepository? remote,
    AtlasEnv? env,
    String? Function()? userIdProvider,
    Duration? syncTimeout,
    @visibleForTesting this.syncEnabledOverride = false,
  })  : _store = store ?? const FavoritesPreferencesStore(),
        _remote = remote ?? const SupabaseFavoritesRepository(),
        _env = env ?? AtlasEnv.fromCompileTime(),
        _userIdProvider = userIdProvider ?? _defaultUserId,
        _syncTimeout = syncTimeout ?? const Duration(seconds: 5),
        super.base();

  final FavoritesPreferencesStore _store;
  final SupabaseFavoritesRepository _remote;
  final AtlasEnv _env;
  final String? Function() _userIdProvider;
  final Duration _syncTimeout;
  @visibleForTesting
  final bool syncEnabledOverride;

  Set<FavoriteKey> _activeFavorites = const {};
  bool _isLoaded = false;
  bool _syncInProgress = false;

  @override
  Set<FavoriteKey> get activeFavorites => _activeFavorites;

  @override
  bool get isLoaded => _isLoaded;

  static String? _defaultUserId() {
    return SupabaseBootstrap.clientOrNull()?.auth.currentUser?.id;
  }

  @override
  bool isFavorite({
    required FavoriteEntityType entityType,
    required String entitySlug,
  }) {
    return _activeFavorites.contains(
      FavoriteKey(entityType: entityType, entitySlug: entitySlug),
    );
  }

  @override
  Future<void> load() async {
    final snapshot = await _store.loadSnapshot();
    _activeFavorites = {
      for (final record in snapshot.activeRecords) record.key,
    };
    _isLoaded = true;
    notifyListeners();
    unawaited(_syncAfterLoad(snapshot));
  }

  @override
  Future<bool> addFavorite({
    required FavoriteEntityType entityType,
    required String entitySlug,
  }) async {
    final sanitizedSlug = FavoriteValidator.sanitizeSlug(entitySlug);
    if (!FavoriteValidator.isValidFavorite(
      entityType: entityType,
      entitySlug: sanitizedSlug,
    )) {
      return false;
    }

    final key = FavoriteKey(entityType: entityType, entitySlug: sanitizedSlug);
    if (_activeFavorites.contains(key)) return true;

    final snapshot = await _store.loadSnapshot();
    final now = DateTime.now().toUtc();
    final record = FavoriteRecord(
      entityType: entityType,
      entitySlug: sanitizedSlug,
      isActive: true,
      updatedAt: now,
    );
    final records = _upsertRecord(snapshot.records, record);

    await _store.saveRecords(records);
    _activeFavorites = {..._activeFavorites, key};
    notifyListeners();

    final pushed = await _pushRecords(records);
    await _store.setSyncPending(!pushed);
    return true;
  }

  @override
  Future<bool> removeFavorite({
    required FavoriteEntityType entityType,
    required String entitySlug,
  }) async {
    final sanitizedSlug = FavoriteValidator.sanitizeSlug(entitySlug);
    if (!FavoriteValidator.isValidFavorite(
      entityType: entityType,
      entitySlug: sanitizedSlug,
    )) {
      return false;
    }

    final key = FavoriteKey(entityType: entityType, entitySlug: sanitizedSlug);
    if (!_activeFavorites.contains(key)) return true;

    final snapshot = await _store.loadSnapshot();
    final now = DateTime.now().toUtc();
    final record = FavoriteRecord(
      entityType: entityType,
      entitySlug: sanitizedSlug,
      isActive: false,
      updatedAt: now,
    );
    final records = _upsertRecord(snapshot.records, record);

    await _store.saveRecords(records);
    _activeFavorites = {..._activeFavorites}..remove(key);
    notifyListeners();

    final pushed = await _pushRecords(records);
    await _store.setSyncPending(!pushed);
    return true;
  }

  @override
  Future<bool> toggleFavorite({
    required FavoriteEntityType entityType,
    required String entitySlug,
  }) {
    if (isFavorite(entityType: entityType, entitySlug: entitySlug)) {
      return removeFavorite(entityType: entityType, entitySlug: entitySlug);
    }
    return addFavorite(entityType: entityType, entitySlug: entitySlug);
  }

  Future<void> _syncAfterLoad(FavoritesLocalSnapshot local) async {
    if (_syncInProgress || !_canSync) return;
    _syncInProgress = true;

    try {
      final userId = _userIdProvider();
      if (userId == null) return;

      final remote = await _fetchRemote(userId);
      final merge = FavoritesSyncCoordinator.merge(local: local, remote: remote);

      if (merge.changed) {
        final pruned = _pruneInactive(merge.records);
        await _store.saveRecords(pruned);
        _activeFavorites = merge.activeKeys;
        notifyListeners();
      }

      if (local.syncPending || merge.shouldPushLocal) {
        final snapshot = await _store.loadSnapshot();
        final pushed = await _pushRecords(snapshot.records);
        await _store.setSyncPending(!pushed);
        if (pushed) {
          final pruned = _pruneInactive(snapshot.records);
          await _store.saveRecords(pruned);
        }
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Atlas] Synchronisation favoris ignorée: $error');
      }
    } finally {
      _syncInProgress = false;
    }
  }

  Future<List<FavoriteRecord>?> _fetchRemote(String userId) async {
    try {
      return await _remote.fetch(userId).timeout(_syncTimeout);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _pushRecords(List<FavoriteRecord> records) async {
    if (!_canSync) return false;

    final userId = _userIdProvider();
    if (userId == null) return false;

    try {
      for (final record in records) {
        await _remote
            .upsert(userId: userId, record: record)
            .timeout(_syncTimeout);
      }
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

  static List<FavoriteRecord> _upsertRecord(
    List<FavoriteRecord> records,
    FavoriteRecord candidate,
  ) {
    return [
      for (final record in records)
        if (record.key != candidate.key) record,
      candidate,
    ];
  }

  static List<FavoriteRecord> _pruneInactive(List<FavoriteRecord> records) {
    return [
      for (final record in records)
        if (record.isActive) record,
    ];
  }
}
