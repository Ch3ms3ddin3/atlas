import '../domain/models/procedure_models.dart';
import '../domain/procedure_repository.dart';
import 'local_procedure_repository.dart';
import 'procedure_mapper.dart';
import 'supabase_procedure_repository.dart';

/// Catalogue éditorial avec repli local si Supabase est indisponible.
class ResilientProcedureRepository implements ProcedureRepository {
  ResilientProcedureRepository({
    LocalProcedureRepository? local,
    Future<List<ProcedureGuide>> Function()? fetchRemote,
    Duration? fetchTimeout,
  })  : _local = local ?? LocalProcedureRepository(),
        _fetchRemote =
            fetchRemote ?? const SupabaseProcedureRepository().fetchAll,
        _fetchTimeout = fetchTimeout ?? const Duration(seconds: 5);

  final LocalProcedureRepository _local;
  final Future<List<ProcedureGuide>> Function() _fetchRemote;
  final Duration _fetchTimeout;

  List<ProcedureGuide>? _remoteCache;
  bool _warmUpStarted = false;

  List<ProcedureGuide> get _source => _remoteCache ?? _local.catalog;

  @override
  Future<void> warmUp() async {
    if (_warmUpStarted) return;
    _warmUpStarted = true;

    try {
      final guides = await _fetchRemote().timeout(_fetchTimeout);
      if (guides.isNotEmpty) {
        _remoteCache = List<ProcedureGuide>.unmodifiable(guides);
      }
    } catch (_) {
      // Repli silencieux sur le catalogue local.
    }
  }

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
