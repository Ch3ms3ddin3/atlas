import 'package:flutter/foundation.dart';

import 'models/price_models.dart';

/// Accès aux repères de prix — indépendant de la source de données.
abstract class PriceRepository {
  static PriceRepository? _instance;
  static PriceRepository Function()? _factory;

  static PriceRepository get instance {
    _instance ??= _factory?.call() ??
        (throw StateError(
          'PriceRepository.registerFactory() must be called before use.',
        ));
    return _instance!;
  }

  factory PriceRepository() => instance;

  static void registerFactory(PriceRepository Function() factory) {
    _factory = factory;
    _instance = null;
  }

  @visibleForTesting
  static void resetForTest() {
    _instance = null;
    _factory = null;
  }

  Future<void> warmUp();

  List<PriceGuide> getAll({String? cityName});

  PriceGuide? findById(String id);

  List<PriceGuide> search(PriceSearchQuery query);

  String resolveCityName(String? cityName);

  bool isCityCovered(String? cityName);

  DateTime get catalogLastReviewedAt;

  List<PriceCategory> get categories;
}
