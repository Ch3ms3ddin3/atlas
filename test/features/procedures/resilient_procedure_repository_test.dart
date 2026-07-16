import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/editorial/editorial_catalog_load_state.dart';
import 'package:atlas/features/procedures/data/local_procedure_repository.dart';
import 'package:atlas/features/procedures/data/procedure_catalog.dart';
import 'package:atlas/features/procedures/data/resilient_procedure_repository.dart';
import 'package:atlas/features/procedures/domain/models/procedure_models.dart';

void main() {
  group('ResilientProcedureRepository', () {
    test('sert le catalogue local immédiatement avant le refresh distant', () {
      final repository = ResilientProcedureRepository(
        local: LocalProcedureRepository(),
        fetchRemote: () async => const [],
      );

      expect(repository.loadState, EditorialCatalogLoadState.idle);
      expect(repository.isUsingRemote, isFalse);
      expect(repository.getAll(), isNotEmpty);
      expect(repository.findById('cin-renewal'), isNotNull);
    });

    test('charge avec succès les données distantes', () async {
      final repository = ResilientProcedureRepository(
        local: LocalProcedureRepository(),
        fetchRemote: () async => const [
          ProcedureGuide(
            id: 'remote-only',
            title: 'Démarche distante',
            summary: 'Résumé distant',
            category: ProcedureCategory.identite,
            categoryLabel: 'Identité',
            estimatedDuration: '1 semaine',
            documents: ['Doc'],
            steps: ['Étape'],
            icon: Icons.badge_outlined,
          ),
        ],
      );

      await repository.warmUp();

      expect(repository.loadState, EditorialCatalogLoadState.success);
      expect(repository.isUsingRemote, isTrue);
      expect(repository.findById('remote-only')?.title, 'Démarche distante');
      expect(repository.findById('cin-renewal'), isNull);
    });

    test('retombe sur le local en error si le distant échoue', () async {
      final repository = ResilientProcedureRepository(
        local: LocalProcedureRepository(),
        fetchRemote: () async => throw Exception('network error'),
      );

      await repository.warmUp();

      expect(repository.loadState, EditorialCatalogLoadState.error);
      expect(repository.lastError, isA<Exception>());
      expect(repository.isUsingRemote, isFalse);
      expect(repository.getAll(), isNotEmpty);
      expect(repository.findById('cin-renewal'), isNotNull);
    });

    test('retombe sur le local en stale si le distant est vide', () async {
      final repository = ResilientProcedureRepository(
        local: LocalProcedureRepository(),
        fetchRemote: () async => const [],
      );

      await repository.warmUp();

      expect(repository.loadState, EditorialCatalogLoadState.stale);
      expect(repository.isUsingRemote, isFalse);
      expect(
        repository.getAll().map((guide) => guide.id),
        ProcedureCatalog.guides.map((guide) => guide.id),
      );
    });

    test('rafraîchit après le démarrage : local puis distant', () async {
      final gate = Completer<void>();
      final repository = ResilientProcedureRepository(
        local: LocalProcedureRepository(),
        fetchRemote: () async {
          await gate.future;
          return const [
            ProcedureGuide(
              id: 'cin-renewal',
              title: 'CIN (cloud)',
              summary: 'Version distante',
              category: ProcedureCategory.identite,
              categoryLabel: 'Identité',
              estimatedDuration: '2 semaines',
              documents: ['CIN'],
              steps: ['Déposer'],
              icon: Icons.badge_outlined,
            ),
          ];
        },
      );

      expect(repository.findById('cin-renewal')!.title, 'Renouveler la CIN');
      expect(repository.loadState, EditorialCatalogLoadState.idle);

      final pending = repository.warmUp();
      await Future<void>.delayed(Duration.zero);
      expect(repository.loadState, EditorialCatalogLoadState.loading);
      expect(repository.findById('cin-renewal')!.title, 'Renouveler la CIN');

      var notified = false;
      repository.addListener(() => notified = true);

      gate.complete();
      await pending;

      expect(repository.loadState, EditorialCatalogLoadState.success);
      expect(repository.findById('cin-renewal')!.title, 'CIN (cloud)');
      expect(notified, isTrue);
    });

    test('conserve recherche, filtre et navigation par slug', () async {
      final repository = ResilientProcedureRepository(
        local: LocalProcedureRepository(),
        fetchRemote: () async => ProcedureCatalog.guides,
      );

      await repository.warmUp();

      final filtered = repository.search(
        const ProcedureSearchQuery(
          text: 'carte',
          category: ProcedureCategory.sejour,
        ),
      );

      expect(filtered.any((guide) => guide.id == 'residence-card'), isTrue);
      expect(
        filtered.every((guide) => guide.category == ProcedureCategory.sejour),
        isTrue,
      );

      // Slugs stables pour favoris / signalements / deep links.
      expect(repository.findById('cin-renewal'), isNotNull);
      expect(repository.findById('driving-license'), isNotNull);
      expect(repository.categories, ProcedureCategory.values);
    });

    test('après échec distant, recherche et filtres restent locaux', () async {
      final repository = ResilientProcedureRepository(
        local: LocalProcedureRepository(),
        fetchRemote: () async => throw Exception('offline'),
      );

      await repository.warmUp();

      final vehicule = repository.search(
        const ProcedureSearchQuery(category: ProcedureCategory.vehicule),
      );

      expect(vehicule, hasLength(1));
      expect(vehicule.first.id, 'admission-temporaire');
    });
  });
}
