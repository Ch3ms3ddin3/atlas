import 'package:flutter/foundation.dart';

import 'models/price_observation.dart';

/// Accès aux observations de prix vérifiées — jamais de valeurs inventées.
abstract class PriceIntelligenceRepository {
  static PriceIntelligenceRepository? _instance;
  static PriceIntelligenceRepository Function()? _factory;

  static PriceIntelligenceRepository get instance {
    _instance ??= _factory?.call() ??
        (throw StateError(
          'PriceIntelligenceRepository.registerFactory() must be called before use.',
        ));
    return _instance!;
  }

  factory PriceIntelligenceRepository() => instance;

  static void registerFactory(PriceIntelligenceRepository Function() factory) {
    _factory = factory;
    _instance = null;
  }

  @visibleForTesting
  static void resetForTest() {
    _instance = null;
    _factory = null;
  }

  Future<void> warmUp();

  /// Rafraîchissement manuel (pull-to-refresh).
  Future<void> refresh();

  List<PriceObservation> getAll({String? cityName});

  PriceObservation? findById(String id);

  List<PriceObservation> search(PriceIntelligenceQuery query);

  /// 3–5 highlights city-aware pour l'accueil.
  List<PriceObservation> highlights({String? cityName, int limit = 5});

  List<String> get availableCities;

  List<PriceIntelligenceCategory> get categories;
}
