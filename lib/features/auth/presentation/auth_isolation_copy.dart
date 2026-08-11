/// Libellés honnêtes pour la frontière d'identité locale (P7).
///
/// Sign-out efface le **local personnel** de cet appareil, sans supprimer le
/// compte cloud. Delete-account efface cloud **et** local. Les deux doivent
/// dire exactement ce que fait [LocalUserDataIsolator].
abstract final class AuthIsolationCopy {
  static const signOutTitle = 'Se déconnecter ?';

  static const signOutBody =
      'Votre compte Atlas n’est pas supprimé. '
      'Les données personnelles de ce compte présentes sur cet appareil '
      '(profil, favoris, préférences, Admission Temporaire, itinéraires, '
      'historique assistant…) seront effacées ici. '
      'En vous reconnectant au même compte, Atlas pourra les restaurer '
      'depuis le cloud si elles y sont synchronisées.';

  static const signOutConfirm = 'Se déconnecter';

  static const signOutSuccess =
      'Déconnecté — données personnelles locales effacées sur cet appareil.';

  static const deleteAccountTitle = 'Supprimer mon compte ?';

  static const deleteAccountBody =
      'Cette action est définitive. Votre compte et vos données cloud seront '
      'supprimés. Les données personnelles locales de ce compte seront '
      'également effacées sur cet appareil.';

  static const deleteAccountConfirm = 'Supprimer';

  static const deleteAccountSuccess =
      'Compte supprimé — données personnelles locales effacées.';

  /// Pied de carte compte — session authentifiée uniquement.
  static const signedInFooter =
      'Sync cloud active · la déconnexion efface le local de cet appareil';
}
