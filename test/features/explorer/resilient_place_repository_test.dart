import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/editorial/editorial_catalog_load_state.dart';
import 'package:atlas/features/explorer/data/local_place_repository.dart';
import 'package:atlas/features/explorer/data/place_catalog.dart';
import 'package:atlas/features/explorer/data/place_record_mapper.dart';
import 'package:atlas/features/explorer/data/resilient_place_repository.dart';
import 'package:atlas/features/explorer/domain/models/place_models.dart';

void main() {
  group('PlaceRecordMapper', () {
    test('mappe une ligne complète y compris les champs optionnels', () {
      final guide = PlaceRecordMapper.fromRow({
        'slug': 'place-majorelle',
        'name': 'Jardin Majorelle',
        'city_name': 'Marrakech',
        'category': 'jardin',
        'category_label': 'Jardin',
        'neighborhood': 'Guéliz',
        'price_level': 'Payant',
        'is_editors_pick': true,
        'image_color': '#C4654A',
        'summary': 'Jardin mythique',
        'practical_tips': ['Réserver'],
        'best_time_to_visit': 'Matin',
        'maps_url': 'https://maps.example/majorelle',
      });

      expect(guide.id, 'place-majorelle');
      expect(guide.category, PlaceCategory.jardin);
      expect(guide.isEditorsPick, isTrue);
      expect(guide.bestTimeToVisit, 'Matin');
      expect(guide.mapsUrl, 'https://maps.example/majorelle');
      expect(guide.imageColor, const Color(0xFFC4654A));
    });

    test('ignore les lignes malformées via tryFromRow', () {
      expect(PlaceRecordMapper.tryFromRow(const {}), isNull);
      expect(
        PlaceRecordMapper.tryFromRow(const {
          'slug': '',
          'name': 'Sans slug',
          'city_name': 'Marrakech',
          'category': 'jardin',
          'category_label': 'Jardin',
          'neighborhood': 'Guéliz',
          'price_level': 'Payant',
          'summary': 'Résumé',
        }),
        isNull,
      );
      expect(
        PlaceRecordMapper.tryFromRow(const {
          'slug': 'place-ok',
          'name': 'OK',
          'city_name': 'Marrakech',
          'category': 'unknown-category',
          'category_label': 'Jardin',
          'neighborhood': 'Guéliz',
          'price_level': 'Payant',
          'summary': 'Résumé',
        }),
        isNotNull,
      );
    });

    test('tolère les optionnels absents', () {
      final guide = PlaceRecordMapper.tryFromRow(const {
        'slug': 'place-minimal',
        'name': 'Minimal',
        'city_name': 'Rabat',
        'category': 'monument',
        'category_label': 'Monument',
        'neighborhood': 'Centre',
        'price_level': 'Gratuit',
        'summary': 'Résumé',
      });

      expect(guide, isNotNull);
      expect(guide!.bestTimeToVisit, isNull);
      expect(guide.mapsUrl, isNull);
      expect(guide.isEditorsPick, isFalse);
      expect(guide.practicalTips, isEmpty);
      expect(guide.hasAddress, isFalse);
      expect(guide.hasCoordinates, isFalse);
      expect(guide.hasGallery, isFalse);
      expect(guide.hasOpeningHours, isFalse);
    });
  });

  group('ResilientPlaceRepository', () {
    test('sert le catalogue local immédiatement avant le refresh distant', () {
      final repository = ResilientPlaceRepository(
        local: LocalPlaceRepository(),
        fetchRemote: () async => const [],
      );

      expect(repository.loadState, EditorialCatalogLoadState.idle);
      expect(repository.isUsingRemote, isFalse);
      expect(repository.getAll(), isNotEmpty);
      expect(repository.findById('place-majorelle'), isNotNull);
    });

    test('charge avec succès les données distantes', () async {
      final repository = ResilientPlaceRepository(
        local: LocalPlaceRepository(),
        fetchRemote: () async => [
          _guide(
            id: 'remote-place',
            name: 'Lieu distant',
            isEditorsPick: true,
          ),
        ],
      );

      await repository.warmUp();

      expect(repository.loadState, EditorialCatalogLoadState.success);
      expect(repository.isUsingRemote, isTrue);
      expect(repository.findById('remote-place')?.name, 'Lieu distant');
      expect(repository.findById('place-majorelle'), isNull);
    });

    test('retombe sur le local en error si le distant échoue', () async {
      final repository = ResilientPlaceRepository(
        local: LocalPlaceRepository(),
        fetchRemote: () async => throw Exception('network error'),
      );

      await repository.warmUp();

      expect(repository.loadState, EditorialCatalogLoadState.error);
      expect(repository.lastError, isA<Exception>());
      expect(repository.isUsingRemote, isFalse);
      expect(repository.findById('place-majorelle'), isNotNull);
    });

    test('retombe sur le local en stale si le distant est vide', () async {
      final repository = ResilientPlaceRepository(
        local: LocalPlaceRepository(),
        fetchRemote: () async => const [],
      );

      await repository.warmUp();

      expect(repository.loadState, EditorialCatalogLoadState.stale);
      expect(repository.isUsingRemote, isFalse);
      expect(
        repository.getAll(cityName: 'Marrakech').map((place) => place.id),
        isNotEmpty,
      );
    });

    test('ignore les lignes distantes malformées sans casser le catalogue', () async {
      final repository = ResilientPlaceRepository(
        local: LocalPlaceRepository(),
        fetchRemote: () async {
          // Simule le filtre côté SupabasePlaceRepository (tryFromRow).
          final rows = [
            <String, dynamic>{
              'slug': 'place-valid-remote',
              'name': 'Valide',
              'city_name': 'Marrakech',
              'category': 'jardin',
              'category_label': 'Jardin',
              'neighborhood': 'Guéliz',
              'price_level': 'Payant',
              'summary': 'OK',
              'is_editors_pick': true,
            },
            <String, dynamic>{
              'slug': '',
              'name': 'Invalide',
            },
          ];
          return [
            for (final row in rows) ?PlaceRecordMapper.tryFromRow(row),
          ];
        },
      );

      await repository.warmUp();

      expect(repository.loadState, EditorialCatalogLoadState.success);
      expect(repository.findById('place-valid-remote'), isNotNull);
      expect(repository.getAll().length, 1);
    });

    test('rafraîchit après le démarrage : local puis distant', () async {
      final gate = Completer<void>();
      final repository = ResilientPlaceRepository(
        local: LocalPlaceRepository(),
        fetchRemote: () async {
          await gate.future;
          return [
            _guide(
              id: 'place-majorelle',
              name: 'Majorelle (cloud)',
              category: PlaceCategory.jardin,
              categoryLabel: 'Jardin',
              isEditorsPick: true,
            ),
          ];
        },
      );

      expect(repository.findById('place-majorelle')!.name, 'Jardin Majorelle');
      expect(repository.loadState, EditorialCatalogLoadState.idle);

      final pending = repository.warmUp();
      await Future<void>.delayed(Duration.zero);
      expect(repository.loadState, EditorialCatalogLoadState.loading);

      var notified = false;
      repository.addListener(() => notified = true);

      gate.complete();
      await pending;

      expect(repository.loadState, EditorialCatalogLoadState.success);
      expect(repository.findById('place-majorelle')!.name, 'Majorelle (cloud)');
      expect(notified, isTrue);
    });

    test('conserve recherche, filtre catégorie et navigation par slug', () async {
      final repository = ResilientPlaceRepository(
        local: LocalPlaceRepository(),
        fetchRemote: () async => PlaceCatalog.guides,
      );

      await repository.warmUp();

      final filtered = repository.search(
        const PlaceSearchQuery(
          cityName: 'Marrakech',
          category: PlaceCategory.jardin,
          text: 'majorelle',
        ),
      );

      expect(filtered.any((place) => place.id == 'place-majorelle'), isTrue);
      expect(
        filtered.every((place) => place.category == PlaceCategory.jardin),
        isTrue,
      );

      // Slugs stables pour favoris / signalements / deep links.
      expect(repository.findById('place-majorelle'), isNotNull);
      expect(repository.findById('place-oudayas'), isNotNull);
      expect(repository.categories, PlaceCategory.values);
    });

    test('Home getFeatured utilise le catalogue distant après refresh', () async {
      final repository = ResilientPlaceRepository(
        local: LocalPlaceRepository(),
        fetchRemote: () async => [
          _guide(
            id: 'place-featured-a',
            name: 'Sélection A',
            cityName: 'Marrakech',
            isEditorsPick: true,
          ),
          _guide(
            id: 'place-featured-b',
            name: 'Sélection B',
            cityName: 'Marrakech',
            isEditorsPick: true,
          ),
          _guide(
            id: 'place-other',
            name: 'Autre',
            cityName: 'Marrakech',
          ),
        ],
      );

      final localFeatured = repository.getFeatured(cityName: 'Marrakech');
      expect(localFeatured, isNotEmpty);

      await repository.warmUp();

      final remoteFeatured = repository.getFeatured(cityName: 'Marrakech');
      expect(remoteFeatured.map((place) => place.id), [
        'place-featured-a',
        'place-featured-b',
      ]);
    });

    test('après échec distant, recherche et filtres restent locaux', () async {
      final repository = ResilientPlaceRepository(
        local: LocalPlaceRepository(),
        fetchRemote: () async => throw Exception('offline'),
      );

      await repository.warmUp();

      final casablanca = repository.search(
        const PlaceSearchQuery(cityName: 'Casablanca'),
      );

      expect(casablanca, isNotEmpty);
      expect(
        casablanca.every((place) => place.cityName == 'Casablanca'),
        isTrue,
      );
    });
  });
}

PlaceGuide _guide({
  required String id,
  required String name,
  String cityName = 'Marrakech',
  PlaceCategory category = PlaceCategory.monument,
  String categoryLabel = 'Monument',
  bool isEditorsPick = false,
}) {
  return PlaceGuide(
    id: id,
    name: name,
    cityName: cityName,
    category: category,
    categoryLabel: categoryLabel,
    neighborhood: 'Médina',
    priceLevel: 'Gratuit',
    isEditorsPick: isEditorsPick,
    imageColor: const Color(0xFF1A2332),
    summary: 'Résumé test',
    practicalTips: const ['Conseil'],
  );
}
