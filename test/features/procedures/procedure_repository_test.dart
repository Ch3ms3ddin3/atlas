import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/procedures/data/local_procedure_repository.dart';
import 'package:atlas/features/procedures/data/procedure_catalog.dart';
import 'package:atlas/features/procedures/data/procedure_mapper.dart';
import 'package:atlas/features/procedures/data/procedure_reminder_links.dart';
import 'package:atlas/features/procedures/domain/models/procedure_models.dart';

void main() {
  group('ProcedureMapper', () {
    test('filtre par catégorie', () {
      final guides = ProcedureMapper.filter(
        const ProcedureSearchQuery(category: ProcedureCategory.vehicule),
      );

      expect(guides, hasLength(1));
      expect(guides.first.id, 'admission-temporaire');
    });

    test('recherche par mot-clé dans le titre', () {
      final guides = ProcedureMapper.filter(
        const ProcedureSearchQuery(text: 'permis'),
      );

      expect(guides.any((guide) => guide.id == 'driving-license'), isTrue);
    });

    test('retourne null pour un identifiant inconnu', () {
      expect(ProcedureMapper.findById('unknown'), isNull);
    });
  });

  group('LocalProcedureRepository', () {
    final repository = LocalProcedureRepository();

    test('expose au moins 7 guides', () {
      expect(repository.getAll().length, greaterThanOrEqualTo(7));
    });

    test('retrouve une démarche par identifiant', () {
      final guide = repository.findById('cin-renewal');

      expect(guide, isNotNull);
      expect(guide!.title, 'Renouveler la CIN');
    });

    test('combine recherche textuelle et filtre catégorie', () {
      final guides = repository.search(
        const ProcedureSearchQuery(
          text: 'carte',
          category: ProcedureCategory.sejour,
        ),
      );

      expect(guides.any((guide) => guide.id == 'residence-card'), isTrue);
      expect(
        guides.every((guide) => guide.category == ProcedureCategory.sejour),
        isTrue,
      );
    });
  });

  group('ProcedureCatalog', () {
    test('contient les démarches clés du MVP', () {
      final ids = ProcedureCatalog.guides.map((guide) => guide.id).toSet();

      expect(ids, containsAll([
        'cin-renewal',
        'residence-card',
        'driving-license',
        'visa-extension',
        'admission-temporaire',
      ]));
    });
  });

  group('ProcedureReminderLinks', () {
    test('associe le rappel CIN au guide correspondant', () {
      expect(
        ProcedureReminderLinks.procedureIdForReminder('admin-cin'),
        'cin-renewal',
      );
    });
  });
}
