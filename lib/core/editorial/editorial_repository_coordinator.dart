import '../../features/events/domain/event_repository.dart';
import '../../features/prices/domain/price_intelligence_repository.dart';
import '../../features/prices/domain/price_repository.dart';
import '../../features/procedures/domain/procedure_repository.dart';
import '../../features/explorer/domain/place_repository.dart';

/// Lance le préchargement Supabase des catalogues éditoriaux.
abstract final class EditorialRepositoryCoordinator {
  static Future<void> warmUp() async {
    await Future.wait([
      ProcedureRepository.instance.warmUp(),
      PlaceRepository.instance.warmUp(),
      PriceRepository.instance.warmUp(),
      PriceIntelligenceRepository.instance.warmUp(),
      EventRepository.instance.warmUp(),
    ]);
  }
}
