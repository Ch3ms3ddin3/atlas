import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/config/atlas_env.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../auth/data/auth_sync_identity.dart';
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
    bool Function()? isSignedInProvider,
    Duration? syncTimeout,
    @visibleForTesting this.syncEnabledOverride = false,
  })  : _store = store ?? const FavoritesPreferencesStore(),
        _remote = remote ?? const SupabaseFavoritesRepository(),
        _env = env ?? AtlasEnv.fromCompileTime(),
        _userIdProvider = userIdProvider ?? _defaultUserId,
        _isSignedInProvider = isSignedInProvider ?? _defaultIsSignedIn,
        // 5s keeps startup off the UI. Reliability comes from a single
        // retry on « Mes favoris », not from a longer timeout alone.
        _syncTimeout = syncTimeout ?? const Duration(seconds: 5),
        super.base();

  final FavoritesPreferencesStore _store;
  final SupabaseFavoritesRepository _remote;
  final AtlasEnv _env;
  final String? Function() _userIdProvider;
  final bool Function() _isSignedInProvider;
  final Duration _syncTimeout;
  @visibleForTesting
  final bool syncEnabledOverride;

  Set<FavoriteKey> _activeFavorites = const {};
  bool _isLoaded = false;
  bool _syncInProgress = false;
  bool _syncQueued = false;
  bool _remoteSyncFailed = false;

  @override
  Set<FavoriteKey> get activeFavorites => _activeFavorites;

  @override
  bool get isLoaded => _isLoaded;

  static String? _defaultUserId() {
    return SupabaseBootstrap.clientOrNull()?.auth.currentUser?.id;
  }

  static bool _defaultIsSignedIn() => SupabaseBootstrap.isSignedInUser;

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
  Future<void> retryFailedRemoteSync() async {
    if (!_remoteSyncFailed) return;
    if (_syncInProgress) return;
    await _syncAfterLoad();
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

    final userIdAtStart = _userIdProvider();
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

    final pushed = await _pushRecords(records, expectedUserId: userIdAtStart);
    if (!AuthSyncIdentity.isStillCurrent(
      capturedUserId: userIdAtStart,
      userIdProvider: _userIdProvider,
    )) {
      return true;
    }
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

    final userIdAtStart = _userIdProvider();
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

    final pushed = await _pushRecords(records, expectedUserId: userIdAtStart);
    if (!AuthSyncIdentity.isStillCurrent(
      capturedUserId: userIdAtStart,
      userIdProvider: _userIdProvider,
    )) {
      return true;
    }
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

      final remoteRead = await _fetchRemote(userId);
      if (!AuthSyncIdentity.isStillCurrent(
        capturedUserId: userId,
        userIdProvider: _userIdProvider,
      )) {
        return;
      }
      if (remoteRead.failed || remoteRead.records == null) {
        _remoteSyncFailed = true;
        return;
      }
      _remoteSyncFailed = false;
      final remote = remoteRead.records!;

      // Relecture après le fetch : un add/remove peut avoir eu lieu pendant l'attente.
      var localSnapshot = await _store.loadSnapshot();
      if (!AuthSyncIdentity.isStillCurrent(
        capturedUserId: userId,
        userIdProvider: _userIdProvider,
      )) {
        return;
      }
      var merge = FavoritesSyncCoordinator.merge(
        local: localSnapshot,
        remote: remote,
      );

      if (merge.changed) {
        final latestSnapshot = await _store.loadSnapshot();
        if (!AuthSyncIdentity.isStillCurrent(
          capturedUserId: userId,
          userIdProvider: _userIdProvider,
        )) {
          return;
        }
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
          if (!AuthSyncIdentity.isStillCurrent(
            capturedUserId: userId,
            userIdProvider: _userIdProvider,
          )) {
            return;
          }
          _activeFavorites = merge.activeKeys;
          notifyListeners();
        }
      }

      if (localSnapshot.syncPending || merge.shouldPushLocal) {
        final snapshot = await _store.loadSnapshot();
        final pushed = await _pushRecords(
          snapshot.records,
          expectedUserId: userId,
        );
        if (!AuthSyncIdentity.isStillCurrent(
          capturedUserId: userId,
          userIdProvider: _userIdProvider,
        )) {
          return;
        }
        await _store.setSyncPending(!pushed);
        if (!pushed) {
          _remoteSyncFailed = true;
        }
        if (pushed) {
          final pruned = _pruneInactive(snapshot.records);
          await _store.saveRecords(pruned);
        }
      }
    } catch (error) {
      _remoteSyncFailed = true;
      _logSyncFailure('synchronisation', error);
    } finally {
      _syncInProgress = false;
      if (_syncQueued) {
        _syncQueued = false;
        unawaited(_syncAfterLoad());
      }
    }
  }

  Future<_RemoteRead> _fetchRemote(String userId) async {
    try {
      final records = await _remote.fetch(userId).timeout(_syncTimeout);
      return _RemoteRead.ok(records);
    } catch (error) {
      _logSyncFailure('lecture distante', error);
      return const _RemoteRead.failed();
    }
  }

  Future<bool> _pushRecords(
    List<FavoriteRecord> records, {
    String? expectedUserId,
  }) async {
    if (!_canSync) return false;

    final userId = _userIdProvider();
    if (userId == null) return false;
    if (expectedUserId != null && userId != expectedUserId) return false;

    try {
      for (final record in records) {
        if (!AuthSyncIdentity.isStillCurrent(
          capturedUserId: expectedUserId ?? userId,
          userIdProvider: _userIdProvider,
        )) {
          return false;
        }
        await _remote
            .upsert(userId: userId, record: record)
            .timeout(_syncTimeout);
      }
      return AuthSyncIdentity.isStillCurrent(
        capturedUserId: expectedUserId ?? userId,
        userIdProvider: _userIdProvider,
      );
    } catch (error) {
      _remoteSyncFailed = true;
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
          _userIdProvider() != null &&
          _isSignedInProvider());

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

/// Lecture distante : l'échec n'expose jamais une liste (vide ou non).
class _RemoteRead {
  const _RemoteRead.ok(List<FavoriteRecord> this.records) : failed = false;

  const _RemoteRead.failed() : records = null, failed = true;

  final List<FavoriteRecord>? records;
  final bool failed;
}
