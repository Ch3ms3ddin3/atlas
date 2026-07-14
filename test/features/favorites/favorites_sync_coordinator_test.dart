import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/favorites/data/favorites_local_snapshot.dart';
import 'package:atlas/features/favorites/data/favorites_sync_coordinator.dart';
import 'package:atlas/features/favorites/domain/favorite_entity_type.dart';
import 'package:atlas/features/favorites/domain/models/favorite_key.dart';
import 'package:atlas/features/favorites/domain/models/favorite_record.dart';

void main() {
  final localTime = DateTime.utc(2026, 7, 10, 12);
  final remoteTime = DateTime.utc(2026, 7, 12, 12);

  final localRecord = FavoriteRecord(
    entityType: FavoriteEntityType.place,
    entitySlug: 'place-jardin-majorelle',
    isActive: true,
    updatedAt: localTime,
  );

  group('FavoritesSyncCoordinator', () {
    test('conserve le local quand le distant est absent', () {
      final result = FavoritesSyncCoordinator.merge(
        local: FavoritesLocalSnapshot(
          records: [
            localRecord.copyWith(updatedAt: localTime),
          ],
          syncPending: true,
        ),
      );

      expect(result.activeKeys, {
        const FavoriteKey(
          entityType: FavoriteEntityType.place,
          entitySlug: 'place-jardin-majorelle',
        ),
      });
      expect(result.changed, isFalse);
      expect(result.shouldPushLocal, isTrue);
    });

    test('applique le distant quand le local est vide', () {
      final result = FavoritesSyncCoordinator.merge(
        local: const FavoritesLocalSnapshot(records: []),
        remote: [
          FavoriteRecord(
            entityType: FavoriteEntityType.price,
            entitySlug: 'price-taxi-marrakech',
            isActive: true,
            updatedAt: remoteTime,
          ),
        ],
      );

      expect(result.activeKeys, {
        const FavoriteKey(
          entityType: FavoriteEntityType.price,
          entitySlug: 'price-taxi-marrakech',
        ),
      });
      expect(result.changed, isTrue);
      expect(result.shouldPushLocal, isFalse);
    });

    test('conserve le local quand il est plus récent', () {
      final result = FavoritesSyncCoordinator.merge(
        local: FavoritesLocalSnapshot(
          records: [
            localRecord.copyWith(updatedAt: remoteTime.add(const Duration(hours: 1))),
          ],
        ),
        remote: [
          FavoriteRecord(
            entityType: FavoriteEntityType.place,
            entitySlug: 'place-jardin-majorelle',
            isActive: false,
            updatedAt: remoteTime,
          ),
        ],
      );

      expect(result.activeKeys, {
        const FavoriteKey(
          entityType: FavoriteEntityType.place,
          entitySlug: 'place-jardin-majorelle',
        ),
      });
      expect(result.changed, isFalse);
      expect(result.shouldPushLocal, isTrue);
    });

    test('applique le distant quand il est plus récent', () {
      final result = FavoritesSyncCoordinator.merge(
        local: FavoritesLocalSnapshot(
          records: [
            localRecord.copyWith(updatedAt: localTime),
          ],
        ),
        remote: [
          FavoriteRecord(
            entityType: FavoriteEntityType.place,
            entitySlug: 'place-jardin-majorelle',
            isActive: false,
            updatedAt: remoteTime,
          ),
        ],
      );

      expect(result.activeKeys, isEmpty);
      expect(result.changed, isTrue);
      expect(result.shouldPushLocal, isFalse);
    });

    test('conserve le local en attente de sync malgré une tombstone distante plus récente', () {
      final result = FavoritesSyncCoordinator.merge(
        local: FavoritesLocalSnapshot(
          records: [
            localRecord.copyWith(updatedAt: localTime),
          ],
          syncPending: true,
        ),
        remote: [
          FavoriteRecord(
            entityType: FavoriteEntityType.place,
            entitySlug: 'place-jardin-majorelle',
            isActive: false,
            updatedAt: remoteTime,
          ),
        ],
      );

      expect(result.activeKeys, {
        const FavoriteKey(
          entityType: FavoriteEntityType.place,
          entitySlug: 'place-jardin-majorelle',
        ),
      });
      expect(result.changed, isFalse);
      expect(result.shouldPushLocal, isTrue);
    });

    test('le local l emporte à timestamps égaux', () {
      final result = FavoritesSyncCoordinator.merge(
        local: FavoritesLocalSnapshot(
          records: [
            localRecord.copyWith(updatedAt: remoteTime),
          ],
        ),
        remote: [
          FavoriteRecord(
            entityType: FavoriteEntityType.place,
            entitySlug: 'place-jardin-majorelle',
            isActive: false,
            updatedAt: remoteTime,
          ),
        ],
      );

      expect(result.activeKeys, {
        const FavoriteKey(
          entityType: FavoriteEntityType.place,
          entitySlug: 'place-jardin-majorelle',
        ),
      });
      expect(result.changed, isFalse);
      expect(result.shouldPushLocal, isTrue);
    });
  });
}
