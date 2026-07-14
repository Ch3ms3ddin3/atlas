import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/procedures/data/local_procedure_repository.dart';
import 'package:atlas/features/procedures/data/resilient_procedure_repository.dart';
import 'package:atlas/features/procedures/domain/models/procedure_models.dart';

void main() {
  group('ResilientProcedureRepository', () {
    test('retombe sur le catalogue local si le distant échoue', () async {
      final repository = ResilientProcedureRepository(
        local: LocalProcedureRepository(),
        fetchRemote: () async => throw Exception('network error'),
      );

      await repository.warmUp();
      final guides = repository.getAll();

      expect(guides, isNotEmpty);
      expect(guides.any((guide) => guide.id == 'cin-renewal'), isTrue);
    });

    test('utilise les données distantes quand disponibles', () async {
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
      final guide = repository.findById('remote-only');

      expect(guide, isNotNull);
      expect(guide!.title, 'Démarche distante');
    });
  });
}
