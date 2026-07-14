import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/features/favorites/data/favorites_preferences_store.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/domain/favorite_entity_type.dart';

void main() {
  group('LocalFavoritesRepository', () {
    test('ajoute et retire un favori localement', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = LocalFavoritesRepository();

      await repository.load();
      expect(repository.activeFavorites, isEmpty);

      final added = await repository.addFavorite(
        entityType: FavoriteEntityType.place,
        entitySlug: 'place-jardin-majorelle',
      );
      expect(added, isTrue);
      expect(repository.isFavorite(
        entityType: FavoriteEntityType.place,
        entitySlug: 'place-jardin-majorelle',
      ), isTrue);

      final removed = await repository.removeFavorite(
        entityType: FavoriteEntityType.place,
        entitySlug: 'place-jardin-majorelle',
      );
      expect(removed, isTrue);
      expect(repository.activeFavorites, isEmpty);

      final snapshot = await const FavoritesPreferencesStore().loadSnapshot();
      expect(snapshot.records, hasLength(1));
      expect(snapshot.records.first.isActive, isFalse);
    });

    test('rejette un slug invalide', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = LocalFavoritesRepository();

      await repository.load();
      final added = await repository.addFavorite(
        entityType: FavoriteEntityType.price,
        entitySlug: '   ',
      );

      expect(added, isFalse);
      expect(repository.activeFavorites, isEmpty);
    });
  });
}
