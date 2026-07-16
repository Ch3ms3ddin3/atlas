import 'package:flutter/foundation.dart';

import '../../../core/editorial/editorial_catalog_load_state.dart';
import '../../../core/editorial/resilient_editorial_catalog.dart';
import '../domain/models/procedure_models.dart';
import '../domain/procedure_repository.dart';
import 'local_procedure_repository.dart';
import 'procedure_mapper.dart';
import 'supabase_procedure_repository.dart';

/// Démarches : local immédiat, puis refresh Supabase via [ResilientEditorialCatalog].
///
/// Les slugs (`ProcedureGuide.id`) restent stables pour favoris et signalements.
class ResilientProcedureRepository
    with ChangeNotifier
    implements ProcedureRepository {
  ResilientProcedureRepository({
    LocalProcedureRepository? local,
    Future<List<ProcedureGuide>> Function()? fetchRemote,
    Duration? fetchTimeout,
  }) : _catalog = ResilientEditorialCatalog<ProcedureGuide>(
          localItems: (local ?? LocalProcedureRepository()).items,
          fetchRemote:
              fetchRemote ?? const SupabaseProcedureRepository().fetchAll,
          fetchTimeout: fetchTimeout,
        ) {
    _catalog.addListener(_onCatalogChanged);
  }

  final ResilientEditorialCatalog<ProcedureGuide> _catalog;

  /// État exposé par l'abstraction éditoriale partagée.
  EditorialCatalogLoadState get loadState => _catalog.loadState;

  /// Dernière erreur distante, si [loadState] est [EditorialCatalogLoadState.error].
  Object? get lastError => _catalog.lastError;

  /// `true` lorsque les données affichées viennent de Supabase.
  bool get isUsingRemote => _catalog.isUsingRemote;

  List<ProcedureGuide> get _source => _catalog.items;

  void _onCatalogChanged() => notifyListeners();

  @override
  void dispose() {
    _catalog.removeListener(_onCatalogChanged);
    _catalog.dispose();
    super.dispose();
  }

  @override
  Future<void> warmUp() => _catalog.warmUp();

  @override
  List<ProcedureGuide> getAll() {
    return List<ProcedureGuide>.unmodifiable(
      ProcedureMapper.filter(const ProcedureSearchQuery(), source: _source),
    );
  }

  @override
  ProcedureGuide? findById(String id) {
    return ProcedureMapper.findById(id, source: _source);
  }

  @override
  List<ProcedureGuide> search(ProcedureSearchQuery query) {
    return ProcedureMapper.filter(query, source: _source);
  }

  @override
  List<ProcedureCategory> get categories => ProcedureCategory.values;
}
