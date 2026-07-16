import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/config/atlas_env.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/favorite_entity_type.dart';
import '../domain/favorites_repository.dart';
import '../domain/models/favorite_key.dart';
import '../domain/models/favorite_record.dart';
import 'favorite_validator.dart';
import 'favorites_preferences_store.dart';
import 'favorites_sync_coordinator.dart';
import 'supabase_favorites_repository.dart';

/// Favoris local d'abord, synchronisation Supabase silencieuse en arrière-plan.
///
/// Flux :
/// 1. `load()` applique SharedPreferences puis fusionne le distant.
/// 2. `addFavorite` / `removeFavorite` écrivent le local immédiatement,
///    marquent `syncPending`, puis tentent un upsert.
/// 3. Si une sync est déjà en cours, une reprise est mise en file d'attente
///    pour ne pas écraser un favori ajouté pendant le fetch distant.
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
  bool _syncQueued = false;

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
    unawaited(_syncAfterLoad());
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
    await _store.setSyncPending(true);
    _activeFavorites = {..._activeFavorites, key};
    notifyListeners();

    final pushed = await _pushRecords(records);
    await _store.setSyncPending(!pushed);
    _scheduleFollowUpSync();
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
    await _store.setSyncPending(true);
    _activeFavorites = {..._activeFavorites}..remove(key);
    notifyListeners();

    final pushed = await _pushRecords(records);
    await _store.setSyncPending(!pushed);
    _scheduleFollowUpSync();
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

  void _scheduleFollowUpSync() {
    if (_syncInProgress) {
      _syncQueued = true;
    }
  }

  /// Pull distant → fusion → push si nécessaire. Ne bloque jamais l'UI.
  Future<void> _syncAfterLoad() async {
    if (_syncInProgress) {
      _syncQueued = true;
      return;
    }
    if (!_canSync) return;

    _syncInProgress = true;

    try {
      final userId = _userIdProvider();
      if (userId == null) return;

      final remote = await _fetchRemote(userId);
      // Relecture après le fetch : un add/remove peut avoir eu lieu pendant l'attente.
      var localSnapshot = await _store.loadSnapshot();
      var merge = FavoritesSyncCoordinator.merge(
        local: localSnapshot,
        remote: remote,
      );

      if (merge.changed) {
        final latestSnapshot = await _store.loadSnapshot();
        if (!FavoritesSyncCoordinator.snapshotsEquivalent(
          localSnapshot,
          latestSnapshot,
        )) {
          localSnapshot = latestSnapshot;
          merge = FavoritesSyncCoordinator.merge(
            local: localSnapshot,
            remote: remote,
          );
        }

        if (merge.changed) {
          final pruned = _pruneInactive(merge.records);
          await _store.saveRecords(pruned);
          _activeFavorites = merge.activeKeys;
          notifyListeners();
        }
      }

      if (localSnapshot.syncPending || merge.shouldPushLocal) {
        final snapshot = await _store.loadSnapshot();
        final pushed = await _pushRecords(snapshot.records);
        await _store.setSyncPending(!pushed);
        if (pushed) {
          final pruned = _pruneInactive(snapshot.records);
          await _store.saveRecords(pruned);
        }
      }
    } catch (error) {
      _logSyncFailure('synchronisation', error);
    } finally {
      _syncInProgress = false;
      if (_syncQueued) {
        _syncQueued = false;
        unawaited(_syncAfterLoad());
      }
    }
  }

  Future<List<FavoriteRecord>?> _fetchRemote(String userId) async {
    try {
      return await _remote.fetch(userId).timeout(_syncTimeout);
    } catch (error) {
      _logSyncFailure('lecture distante', error);
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
    } catch (error) {
      _logSyncFailure('écriture distante', error);
      return false;
    }
  }

  static void _logSyncFailure(String operation, Object error) {
    if (!kDebugMode) return;
    debugPrint(
      '[Atlas] Synchronisation favoris ignorée ($operation): $error',
    );
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

  /// Les tombstones distantes restent en base ; en local on ne garde que les actifs.
  static List<FavoriteRecord> _pruneInactive(List<FavoriteRecord> records) {
    return [
      for (final record in records)
        if (record.isActive) record,
    ];
  }
}
