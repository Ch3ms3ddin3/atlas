import '../../../core/editorial/editorial_local_catalog.dart';
import '../domain/models/procedure_models.dart';
import '../domain/procedure_repository.dart';
import 'procedure_catalog.dart';
import 'procedure_mapper.dart';

/// Catalogue statique local — repli permanent et hors-ligne.
class LocalProcedureRepository
    implements ProcedureRepository, EditorialLocalCatalog<ProcedureGuide> {
  LocalProcedureRepository();

  List<ProcedureGuide> get catalog =>
      List<ProcedureGuide>.unmodifiable(ProcedureCatalog.guides);

  @override
  List<ProcedureGuide> get items => catalog;

  @override
  Future<void> warmUp() async {}

  @override
  List<ProcedureGuide> getAll() {
    return List<ProcedureGuide>.unmodifiable(
      ProcedureMapper.filter(const ProcedureSearchQuery()),
    );
  }

  @override
  ProcedureGuide? findById(String id) {
    return ProcedureMapper.findById(id);
  }

  @override
  List<ProcedureGuide> search(ProcedureSearchQuery query) {
    return ProcedureMapper.filter(query);
  }

  @override
  List<ProcedureCategory> get categories => ProcedureCategory.values;
}
