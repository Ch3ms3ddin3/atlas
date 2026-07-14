import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/core/config/atlas_env.dart';
import 'package:atlas/features/favorites/data/favorites_preferences_store.dart';
import 'package:atlas/features/favorites/data/supabase_favorites_repository.dart';
import 'package:atlas/features/favorites/data/syncing_favorites_repository.dart';
import 'package:atlas/features/favorites/domain/favorite_entity_type.dart';
import 'package:atlas/features/favorites/domain/models/favorite_key.dart';
import 'package:atlas/features/favorites/domain/models/favorite_record.dart';

void main() {
  group('SyncingFavoritesRepository', () {
    test('retombe sur le local quand la synchronisation est indisponible', () async {
      SharedPreferences.setMockInitialValues({});
      final store = FavoritesPreferencesStore();
      final repository = SyncingFavoritesRepository(
        store: store,
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: '',
          supabaseAnonKey: '',
        ),
        remote: _FailingRemoteRepository(),
        userIdProvider: () => 'user-1',
      );

      await repository.load();

      expect(repository.isLoaded, isTrue);
      expect(repository.activeFavorites, isEmpty);
    });

    test('applique les favoris distants au chargement', () async {
      SharedPreferences.setMockInitialValues({});
      final store = FavoritesPreferencesStore();
      final repository = SyncingFavoritesRepository(
        store: store,
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: 'https://example.supabase.co',
          supabaseAnonKey: 'anon-key',
        ),
        remote: _StubRemoteRepository(),
        userIdProvider: () => 'user-1',
        syncEnabledOverride: true,
        syncTimeout: const Duration(milliseconds: 100),
      );

      await repository.load();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        repository.activeFavorites,
        {
          const FavoriteKey(
            entityType: FavoriteEntityType.place,
            entitySlug: 'place-jardin-majorelle',
          ),
        },
      );
    });

    test('marque sync_pending quand le push distant échoue', () async {
      SharedPreferences.setMockInitialValues({});
      final store = FavoritesPreferencesStore();
      final repository = SyncingFavoritesRepository(
        store: store,
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: 'https://example.supabase.co',
          supabaseAnonKey: 'anon-key',
        ),
        remote: _FailingRemoteRepository(),
        userIdProvider: () => 'user-1',
        syncEnabledOverride: true,
      );

      final added = await repository.addFavorite(
        entityType: FavoriteEntityType.price,
        entitySlug: 'price-taxi-marrakech',
      );

      expect(added, isTrue);
      expect(repository.isFavorite(
        entityType: FavoriteEntityType.price,
        entitySlug: 'price-taxi-marrakech',
      ), isTrue);

      final snapshot = await store.loadSnapshot();
      expect(snapshot.syncPending, isTrue);
    });

    test('conserve un favori local après rechargement malgré une tombstone distante plus récente', () async {
      SharedPreferences.setMockInitialValues({});
      final store = FavoritesPreferencesStore();
      final remote = _RemoteWithNewerInactiveTombstone();
      final repository = SyncingFavoritesRepository(
        store: store,
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: 'https://example.supabase.co',
          supabaseAnonKey: 'anon-key',
        ),
        remote: remote,
        userIdProvider: () => 'user-1',
        syncEnabledOverride: true,
        syncTimeout: const Duration(milliseconds: 100),
      );

      await repository.load();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await repository.addFavorite(
        entityType: FavoriteEntityType.place,
        entitySlug: 'place-majorelle',
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      await repository.load();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(
        repository.isFavorite(
          entityType: FavoriteEntityType.place,
          entitySlug: 'place-majorelle',
        ),
        isTrue,
      );
      expect((await store.loadSnapshot()).records, isNotEmpty);
    });

    test('ne supprime pas un favori ajouté pendant une synchronisation en cours', () async {
      SharedPreferences.setMockInitialValues({});
      final store = FavoritesPreferencesStore();
      final gate = Completer<void>();
      final remote = _SlowRemoteWithNewerInactiveTombstone(gate);
      final repository = SyncingFavoritesRepository(
        store: store,
        env: const AtlasEnv(
          environment: AtlasEnvironment.development,
          supabaseUrl: 'https://example.supabase.co',
          supabaseAnonKey: 'anon-key',
        ),
        remote: remote,
        userIdProvider: () => 'user-1',
        syncEnabledOverride: true,
        syncTimeout: const Duration(seconds: 5),
      );

      await repository.load();
      await repository.addFavorite(
        entityType: FavoriteEntityType.place,
        entitySlug: 'place-majorelle',
      );
      gate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(
        repository.isFavorite(
          entityType: FavoriteEntityType.place,
          entitySlug: 'place-majorelle',
        ),
        isTrue,
      );
      expect((await store.loadSnapshot()).records, isNotEmpty);
    });
  });
}

class _FailingRemoteRepository extends SupabaseFavoritesRepository {
  _FailingRemoteRepository()
      : super(clientProvider: () => throw StateError('no client'));

  @override
  Future<List<FavoriteRecord>> fetch(String userId) async {
    throw Exception('network error');
  }

  @override
  Future<void> upsert({
    required String userId,
    required FavoriteRecord record,
  }) async {
    throw Exception('network error');
  }
}

class _StubRemoteRepository extends SupabaseFavoritesRepository {
  _StubRemoteRepository()
      : super(clientProvider: () => throw StateError('no client'));

  @override
  Future<List<FavoriteRecord>> fetch(String userId) async {
    return [
      FavoriteRecord(
        entityType: FavoriteEntityType.place,
        entitySlug: 'place-jardin-majorelle',
        isActive: true,
        updatedAt: DateTime.utc(2026, 7, 12, 10),
      ),
    ];
  }

  @override
  Future<void> upsert({
    required String userId,
    required FavoriteRecord record,
  }) async {}
}

class _RemoteWithNewerInactiveTombstone extends SupabaseFavoritesRepository {
  _RemoteWithNewerInactiveTombstone()
      : super(clientProvider: () => throw StateError('no client'));

  @override
  Future<List<FavoriteRecord>> fetch(String userId) async {
    return [
      FavoriteRecord(
        entityType: FavoriteEntityType.place,
        entitySlug: 'place-majorelle',
        isActive: false,
        updatedAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
    ];
  }

  @override
  Future<void> upsert({
    required String userId,
    required FavoriteRecord record,
  }) async {
    throw Exception('network error');
  }
}

class _SlowRemoteWithNewerInactiveTombstone extends SupabaseFavoritesRepository {
  _SlowRemoteWithNewerInactiveTombstone(this._gate)
      : super(clientProvider: () => throw StateError('no client'));

  final Completer<void> _gate;

  @override
  Future<List<FavoriteRecord>> fetch(String userId) async {
    await _gate.future;
    return [
      FavoriteRecord(
        entityType: FavoriteEntityType.place,
        entitySlug: 'place-majorelle',
        isActive: false,
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    ];
  }

  @override
  Future<void> upsert({
    required String userId,
    required FavoriteRecord record,
  }) async {}
}
