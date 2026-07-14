import 'package:flutter/foundation.dart';

import 'models/user_profile.dart';

/// Accès au profil utilisateur — indépendant de Supabase.
abstract class ProfileRepository extends ChangeNotifier {
  ProfileRepository.base();

  UserProfile get profile;

  bool get isLoaded;

  Future<void> load();

  Future<bool> save(UserProfile candidate);
}
