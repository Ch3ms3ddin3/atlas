import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/presentation/pages/place_detail_page.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/favorites/domain/favorite_entity_type.dart';
import 'package:atlas/features/favorites/domain/models/favorite_key.dart';
import 'package:atlas/features/favorites/presentation/favorites_scope.dart';
import 'package:atlas/features/procedures/data/local_procedure_repository.dart';
import 'package:atlas/features/procedures/presentation/pages/procedure_detail_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FavoriteToggleButton on detail pages', () {
    testWidgets('PlaceDetailPage ajoute et retire un favori', (
      WidgetTester tester,
    ) async {
      final favoritesRepository = LocalFavoritesRepository();
      await favoritesRepository.load();

      final place = LocalPlaceRepository().findById('place-majorelle')!;

      await tester.pumpWidget(
        MaterialApp(
          home: FavoritesScope(
            repository: favoritesRepository,
            child: PlaceDetailPage(place: place),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);

      await tester.tap(find.byTooltip('Ajouter aux favoris'));
      await tester.pump();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
      expect(
        favoritesRepository.isFavorite(
          entityType: FavoriteEntityType.place,
          entitySlug: 'place-majorelle',
        ),
        isTrue,
      );

      await tester.tap(find.byTooltip('Retirer des favoris'));
      await tester.pump();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
      expect(favoritesRepository.activeFavorites, isEmpty);
    });

    testWidgets('ProcedureDetailPage ajoute et retire un favori', (
      WidgetTester tester,
    ) async {
      final favoritesRepository = LocalFavoritesRepository();
      await favoritesRepository.load();

      final guide = LocalProcedureRepository().findById('cin-renewal')!;

      await tester.pumpWidget(
        MaterialApp(
          home: FavoritesScope(
            repository: favoritesRepository,
            child: ProcedureDetailPage(guide: guide),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      await tester.tap(find.byTooltip('Ajouter aux favoris'));
      await tester.pump();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(
        favoritesRepository.activeFavorites,
        {
          const FavoriteKey(
            entityType: FavoriteEntityType.procedure,
            entitySlug: 'cin-renewal',
          ),
        },
      );

      await tester.tap(find.byTooltip('Retirer des favoris'));
      await tester.pump();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(favoritesRepository.activeFavorites, isEmpty);
    });
  });
}
