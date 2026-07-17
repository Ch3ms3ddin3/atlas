import 'package:atlas/features/prices/data/resilient_price_intelligence_repository.dart';
import 'package:atlas/features/prices/domain/price_intelligence_repository.dart';

import 'price_intelligence_fixtures.dart';

/// Enregistre un dépôt Intelligence avec fixtures vérifiées (tests UI uniquement).
void registerPriceIntelligenceFixtures() {
  PriceIntelligenceRepository.registerFactory(
    () => ResilientPriceIntelligenceRepository(
      seedItems: PriceIntelligenceFixtures.sample,
      fetchRemote: () async => PriceIntelligenceFixtures.sample,
    ),
  );
}
