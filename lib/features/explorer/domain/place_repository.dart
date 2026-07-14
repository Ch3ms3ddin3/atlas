import 'package:flutter/foundation.dart';

import '../domain/models/place_models.dart';

/// Accès aux lieux utiles — indépendant de la source de données.
abstract class PlaceRepository {
  static PlaceRepository? _instance;
  static PlaceRepository Function()? _factory;

  static PlaceRepository get instance {
    _instance ??= _factory?.call() ??
        (throw StateError(
          'PlaceRepository.registerFactory() must be called before use.',
        ));
    return _instance!;
  }

  factory PlaceRepository() => instance;

  static void registerFactory(PlaceRepository Function() factory) {
    _factory = factory;
    _instance = null;
  }

  @visibleForTesting
  static void resetForTest() {
    _instance = null;
    _factory = null;
  }

  Future<void> warmUp();

  List<PlaceGuide> getAll({String? cityName});

  List<PlaceGuide> getFeatured({String? cityName, int limit = 2});

  PlaceGuide? findById(String id);

  List<PlaceGuide> search(PlaceSearchQuery query);

  String resolveCityName(String? cityName);

  bool isCityCovered(String? cityName);

  List<PlaceCategory> get categories;
}
