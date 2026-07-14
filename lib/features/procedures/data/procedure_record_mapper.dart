import '../../../core/icons/atlas_material_icons.dart';
import '../domain/models/procedure_models.dart';

/// Convertit une ligne Supabase vers [ProcedureGuide].
abstract final class ProcedureRecordMapper {
  static ProcedureGuide fromRow(Map<String, dynamic> row) {
    final category = ProcedureCategory.values.firstWhere(
      (value) => value.name == row['category'],
      orElse: () => ProcedureCategory.identite,
    );

    return ProcedureGuide(
      id: row['slug'] as String,
      title: row['title'] as String,
      summary: row['summary'] as String,
      category: category,
      categoryLabel: row['category_label'] as String,
      estimatedDuration: row['estimated_duration'] as String,
      icon: AtlasMaterialIcons.resolve(row['icon_key'] as String?),
      officialUrl: row['official_url'] as String?,
      documents: _readStringList(row['documents']),
      steps: _readStringList(row['steps']),
    );
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }
}
