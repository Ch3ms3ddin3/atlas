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
