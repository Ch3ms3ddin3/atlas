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

    test('mappe image primaire et image_urls vers PlaceGuide.imageUrls', () {
      final guide = PlaceRecordMapper.fromRow({
        'slug': 'place-majorelle',
        'name': 'Jardin Majorelle',
        'city_name': 'Marrakech',
        'category': 'Jardin',
        'category_label': 'Jardin & culture',
        'neighborhood': 'Guéliz',
        'price_level': '€€',
        'summary': 'Jardin mythique',
        'image': 'https://cdn.example/cover.webp',
        'image_urls': [
          'https://cdn.example/cover.webp',
          'https://cdn.example/gallery-1.webp',
        ],
      });

      expect(guide.category, PlaceCategory.jardin);
      expect(guide.primaryImageUrl, 'https://cdn.example/cover.webp');
      expect(guide.imageUrls, [
        'https://cdn.example/cover.webp',
        'https://cdn.example/gallery-1.webp',
      ]);
    });

    test('accepte category FR et image seule sans image_urls', () {
      final guide = PlaceRecordMapper.tryFromRow({
        'slug': 'place-ysl',
        'name': 'Musée YSL',
        'city_name': 'Marrakech',
        'category': 'Musée',
        'category_label': 'Musée',
        'neighborhood': 'Guéliz',
        'price_level': '€€€',
        'summary': 'Musée',
        'image': 'https://cdn.example/ysl.jpg',
      });

      expect(guide, isNotNull);
      expect(guide!.category, PlaceCategory.musee);
      expect(guide.primaryImageUrl, 'https://cdn.example/ysl.jpg');
      expect(guide.hasPrimaryImage, isTrue);
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

    test(
      'charge avec succès les données distantes fusionnées au local',
      () async {
        final localIds = LocalPlaceRepository().items
            .map((place) => place.id)
            .toSet();
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
        // Lieux locaux conservés — le distant partiel ne remplace pas le catalogue.
        for (final id in localIds) {
          expect(repository.findById(id), isNotNull, reason: 'local id $id');
        }
      },
    );

    test(
      'fusion : distant override le même id, local-only conservé, sans doublon',
      () async {
        final local = LocalPlaceRepository();
        final localIds = local.items.map((place) => place.id).toSet();
        final repository = ResilientPlaceRepository(
          local: local,
          fetchRemote: () async => [
            _guide(
              id: 'place-majorelle',
              name: 'Majorelle (Supabase)',
              category: PlaceCategory.jardin,
              categoryLabel: 'Jardin',
              isEditorsPick: true,
            ),
            _guide(id: 'remote-only', name: 'Nouveau distant'),
          ],
        );

        await repository.warmUp();

        expect(repository.loadState, EditorialCatalogLoadState.success);
        expect(
          repository.findById('place-majorelle')!.name,
          'Majorelle (Supabase)',
        );
        expect(repository.findById('place-bahia'), isNotNull);
        expect(repository.findById('remote-only'), isNotNull);

        for (final id in localIds) {
          expect(repository.findById(id), isNotNull, reason: 'local id $id');
        }

        final marrakechIds = repository
            .getAll(cityName: 'Marrakech')
            .map((place) => place.id)
            .toList();
        expect(marrakechIds.toSet().length, marrakechIds.length);
        expect(marrakechIds.where((id) => id == 'place-majorelle').length, 1);
      },
    );

    test('fusion pure : override id, conserve local-only, aucun doublon', () {
      final local = [
        _guide(id: 'a', name: 'Local A'),
        _guide(id: 'b', name: 'Local B'),
      ];
      final remote = [
        _guide(id: 'a', name: 'Remote A'),
        _guide(id: 'c', name: 'Remote C'),
      ];

      final merged = ResilientPlaceRepository.mergeRemoteOverLocal(
        local: local,
        remote: remote,
      );

      expect(merged.map((place) => place.id), ['a', 'b', 'c']);
      expect(merged.map((place) => place.name), [
        'Remote A',
        'Local B',
        'Remote C',
      ]);
      expect(merged.map((place) => place.id).toSet().length, merged.length);
    });

    test('distant vide ne déclenche pas de fusion (repli local via stale)', () {
      final merged = ResilientPlaceRepository.mergeRemoteOverLocal(
        local: [_guide(id: 'a', name: 'Local A')],
        remote: const [],
      );
      expect(merged, isEmpty);
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

    test(
      'ignore les lignes distantes malformées sans casser le catalogue',
      () async {
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
              <String, dynamic>{'slug': '', 'name': 'Invalide'},
            ];
            return [for (final row in rows) ?PlaceRecordMapper.tryFromRow(row)];
          },
        );

        await repository.warmUp();

        expect(repository.loadState, EditorialCatalogLoadState.success);
        expect(repository.findById('place-valid-remote'), isNotNull);
        expect(repository.findById('place-majorelle'), isNotNull);
        expect(repository.findById('place-hassan-ii'), isNotNull);
        expect(repository.findById('place-oudayas'), isNotNull);
      },
    );

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
      expect(repository.findById('place-bahia'), isNotNull);
      expect(notified, isTrue);
    });

    test(
      'conserve recherche, filtre catégorie et navigation par slug',
      () async {
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
        expect(repository.categories, isNot(contains(PlaceCategory.cafe)));
        expect(repository.categories, contains(PlaceCategory.restaurant));
        expect(repository.categories, contains(PlaceCategory.plage));
      },
    );

    test(
      'Home getFeatured voit les sélections distantes après fusion',
      () async {
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
            _guide(id: 'place-other', name: 'Autre', cityName: 'Marrakech'),
          ],
        );

        final localFeatured = repository.getFeatured(cityName: 'Marrakech');
        expect(localFeatured, isNotEmpty);

        await repository.warmUp();

        expect(repository.findById('place-featured-a'), isNotNull);
        expect(repository.findById('place-featured-b'), isNotNull);
        // Catalogue local toujours présent après distant partiel.
        expect(repository.findById('place-majorelle'), isNotNull);
        final featuredIds = repository
            .getFeatured(cityName: 'Marrakech', limit: 20)
            .map((place) => place.id)
            .toSet();
        expect(featuredIds.contains('place-featured-a'), isTrue);
        expect(featuredIds.contains('place-featured-b'), isTrue);
      },
    );

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

  group('P0 Explorer catalog ↔ Supabase representation', () {
    /// Slugs stables — doivent rester alignés avec Favorites (`entity_slug`).
    const expectedSlugs = <String>{
      'place-majorelle',
      'place-bahia',
      'place-jemaa-el-fna',
      'place-ysl-museum',
      'place-hammam-marrakech',
      'place-hassan-ii',
      'place-corniche',
      'place-marche-central',
      'place-musee-judaisme',
      'place-habous',
      'place-tour-hassan',
      'place-oudayas',
      'place-chellah',
      'place-musee-rabat',
      'place-plage-rabat',
    };

    test('catalogue local : 15 slugs stables, uniques, sans nouveau lieu', () {
      final ids = PlaceCatalog.guides.map((place) => place.id).toList();
      expect(ids.toSet(), expectedSlugs);
      expect(ids.toSet().length, ids.length);
      expect(ids, hasLength(15));
    });

    test(
      'chaque lieu local est représentable par le schéma Supabase (mapper)',
      () {
        for (final place in PlaceCatalog.guides) {
          final row = _supabaseRowFromGuide(place);
          final mapped = PlaceRecordMapper.tryFromRow(row);
          expect(mapped, isNotNull, reason: place.id);
          expect(mapped!.id, place.id);
          expect(mapped.name, place.name);
          expect(mapped.cityName, place.cityName);
          expect(mapped.category, place.category);
          expect(mapped.categoryLabel, place.categoryLabel);
          expect(mapped.neighborhood, place.neighborhood);
          expect(mapped.priceLevel, place.priceLevel);
          expect(mapped.isEditorsPick, place.isEditorsPick);
          expect(mapped.summary, place.summary);
          expect(mapped.practicalTips, place.practicalTips);
          expect(mapped.bestTimeToVisit, place.bestTimeToVisit);
          expect(mapped.mapsUrl, place.mapsUrl);
          expect(mapped.latitude, place.latitude);
          expect(mapped.longitude, place.longitude);
          expect(mapped.imageUrls, place.imageUrls);
        }
      },
    );

    test(
      'distant partiel (majorelle seul) : merge conserve le catalogue complet',
      () async {
        final local = LocalPlaceRepository();
        final localIds = local.items.map((place) => place.id).toSet();
        expect(localIds, expectedSlugs);

        final remoteMajorelle = PlaceRecordMapper.fromRow(
          _supabaseRowFromGuide(
            PlaceCatalog.guides.firstWhere((p) => p.id == 'place-majorelle'),
          )..['name'] = 'Jardin Majorelle (Supabase)',
        );

        final repository = ResilientPlaceRepository(
          local: local,
          fetchRemote: () async => [remoteMajorelle],
        );

        await repository.warmUp();

        expect(repository.loadState, EditorialCatalogLoadState.success);
        expect(repository.isUsingRemote, isTrue);
        expect(
          repository.findById('place-majorelle')!.name,
          'Jardin Majorelle (Supabase)',
        );

        // getAll() sans ville se résout sur Marrakech — le catalogue
        // fusionné complet se vérifie par slug (toutes villes).
        for (final id in expectedSlugs) {
          expect(repository.findById(id), isNotNull, reason: id);
        }
        expect({
          for (final city in ['Marrakech', 'Casablanca', 'Rabat'])
            ...repository.getAll(cityName: city).map((place) => place.id),
        }, expectedSlugs);
      },
    );

    test(
      'mergeRemoteOverLocal : distant partiel ne retire aucun lieu local',
      () {
        final local = PlaceCatalog.guides;
        final remote = [
          PlaceRecordMapper.fromRow(
            _supabaseRowFromGuide(local.first)..['name'] = 'Override distant',
          ),
        ];

        final merged = ResilientPlaceRepository.mergeRemoteOverLocal(
          local: local,
          remote: remote,
        );

        expect(merged.map((place) => place.id).toSet(), expectedSlugs);
        expect(
          merged.where((place) => place.id == local.first.id).single.name,
          'Override distant',
        );
        expect(merged.length, local.length);
      },
    );
  });
}

/// Ligne Supabase synthétique alignée sur `places` (00002 + 00006 + 00013).
Map<String, dynamic> _supabaseRowFromGuide(PlaceGuide place) {
  final color =
      '#${place.imageColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  return <String, dynamic>{
    'slug': place.id,
    'name': place.name,
    'city_name': place.cityName,
    'category': place.category.name,
    'category_label': place.categoryLabel,
    'neighborhood': place.neighborhood,
    'price_level': place.priceLevel,
    'is_editors_pick': place.isEditorsPick,
    'image_color': color,
    'summary': place.summary,
    'practical_tips': place.practicalTips,
    'best_time_to_visit': place.bestTimeToVisit,
    'maps_url': place.mapsUrl,
    'address': place.address,
    'latitude': place.latitude,
    'longitude': place.longitude,
    'phone': place.phone,
    'website': place.website,
    'email': place.email,
    'image_urls': place.imageUrls,
    'amenities': place.amenities,
    'accessibility_features': place.accessibilityFeatures,
    'opening_hours': null,
    'image': place.primaryImageUrl,
    'is_published': true,
  };
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
