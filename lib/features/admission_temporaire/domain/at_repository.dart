import 'package:flutter/foundation.dart';

import '../domain/models/at_vehicle.dart';

/// Accès aux véhicules suivis — indépendant de Supabase.
///
/// Les implémentations notifient après chargement et mutations.
abstract class AtRepository extends ChangeNotifier {
  AtRepository.base();

  bool get isLoaded;

  List<AtVehicle> get vehicles;

  List<AtVehicle> get activeVehicles;

  bool get notificationsEnabled;

  bool get notificationPromptShown;

  Future<void> load();

  /// Ajoute un véhicule actif. Retourne `false` si invalide.
  Future<bool> addVehicle(AtVehicle vehicle);

  /// Met à jour un véhicule existant.
  Future<bool> updateVehicle(AtVehicle vehicle);

  /// Soft-delete (isActive = false) pour compatibilité sync future.
  Future<bool> deleteVehicle(String id);

  Future<void> setNotificationsEnabled(bool enabled);

  Future<void> markNotificationPromptShown();
}
