import 'package:flutter/foundation.dart';

import 'models/price_observation.dart';

/// Accès aux observations de prix vérifiées — jamais de valeurs inventées.
abstract class PriceIntelligenceRepository {
  static PriceIntelligenceRepository? _instance;
  static PriceIntelligenceRepository Function()? _factory;

  static PriceIntelligenceRepository get instance {
    _instance ??=
        _factory?.call() ??
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

  /// Highlights city-aware (listes / diversités).
  List<PriceObservation> highlights({
    String? cityName,
    int limit = 5,
    bool strictCity = false,
  });

  /// Accueil « Prix utiles » — ville stricte, max 2, sans repli inter-villes.
  List<PriceObservation> homeHighlights({
    String? cityName,
    int limit = 2,
    Set<String> excludeIds = const {},
  });

  List<String> get availableCities;

  List<PriceIntelligenceCategory> get categories;
}
