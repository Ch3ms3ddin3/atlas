import '../domain/models/procedure_models.dart';
import 'procedure_mapper.dart';

/// Accès au catalogue local des démarches administratives.
class ProcedureRepository {
  const ProcedureRepository();

  List<ProcedureGuide> getAll() {
    return List<ProcedureGuide>.unmodifiable(ProcedureMapper.filter(
      const ProcedureSearchQuery(),
    ));
  }

  ProcedureGuide? findById(String id) {
    return ProcedureMapper.findById(id);
  }

  List<ProcedureGuide> search(ProcedureSearchQuery query) {
    return ProcedureMapper.filter(query);
  }

  List<ProcedureCategory> get categories => ProcedureCategory.values;
}
