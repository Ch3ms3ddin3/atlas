import '../../features/explorer/data/local_place_repository.dart';
import '../../features/explorer/data/resilient_place_repository.dart';
import '../../features/explorer/domain/place_repository.dart';
import '../../features/prices/data/local_price_repository.dart';
import '../../features/prices/data/resilient_price_repository.dart';
import '../../features/prices/domain/price_repository.dart';
import '../../features/procedures/data/local_procedure_repository.dart';
import '../../features/procedures/data/resilient_procedure_repository.dart';
import '../../features/procedures/domain/procedure_repository.dart';
import 'editorial_repository_coordinator.dart';

/// Enregistre les dépôts éditoriaux résilients au démarrage.
abstract final class EditorialRepositoryBootstrap {
  static void registerDefaults() {
    ProcedureRepository.registerFactory(
      () => ResilientProcedureRepository(
        local: LocalProcedureRepository(),
      ),
    );
    PlaceRepository.registerFactory(
      () => ResilientPlaceRepository(
        local: LocalPlaceRepository(),
      ),
    );
    PriceRepository.registerFactory(
      () => ResilientPriceRepository(
        local: LocalPriceRepository(),
      ),
    );
  }

  static Future<void> warmUp() => EditorialRepositoryCoordinator.warmUp();
}
