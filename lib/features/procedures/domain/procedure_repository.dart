import 'package:flutter/foundation.dart';

import 'models/procedure_models.dart';

/// Accès aux guides de démarches — indépendant de la source de données.
abstract class ProcedureRepository {
  static ProcedureRepository? _instance;
  static ProcedureRepository Function()? _factory;

  /// Instance partagée ; [registerFactory] doit être appelé au démarrage.
  static ProcedureRepository get instance {
    _instance ??= _factory?.call() ??
        (throw StateError(
          'ProcedureRepository.registerFactory() must be called before use.',
        ));
    return _instance!;
  }

  /// Raccourci vers [instance].
  factory ProcedureRepository() => instance;

  /// Enregistre l'implémentation par défaut (appelé une fois au bootstrap).
  static void registerFactory(ProcedureRepository Function() factory) {
    _factory = factory;
    _instance = null;
  }

  @visibleForTesting
  static void resetForTest() {
    _instance = null;
    _factory = null;
  }

  /// Précharge les données distantes si Supabase est configuré.
  Future<void> warmUp();

  List<ProcedureGuide> getAll();

  ProcedureGuide? findById(String id);

  List<ProcedureGuide> search(ProcedureSearchQuery query);

  List<ProcedureCategory> get categories;
}
