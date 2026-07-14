import '../domain/models/procedure_models.dart';
import 'procedure_catalog.dart';

/// Filtre et recherche dans le catalogue statique.
abstract final class ProcedureMapper {
  static const categoryLabels = {
    ProcedureCategory.identite: 'Identité',
    ProcedureCategory.sejour: 'Séjour',
    ProcedureCategory.vehicule: 'Véhicule',
    ProcedureCategory.transport: 'Transport',
  };

  static List<ProcedureGuide> filter(
    ProcedureSearchQuery query, {
    List<ProcedureGuide>? source,
  }) {
    final guides = source ?? ProcedureCatalog.guides;
    final normalizedQuery = query.text.trim().toLowerCase();

    return guides.where((guide) {
      final matchesCategory =
          query.category == null || guide.category == query.category;
      if (!matchesCategory) return false;
      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        guide.title,
        guide.summary,
        guide.categoryLabel,
      ].join(' ').toLowerCase();

      return haystack.contains(normalizedQuery);
    }).toList();
  }

  static ProcedureGuide? findById(
    String id, {
    List<ProcedureGuide>? source,
  }) {
    final guides = source ?? ProcedureCatalog.guides;
    for (final guide in guides) {
      if (guide.id == id) return guide;
    }
    return null;
  }
}
