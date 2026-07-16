/// État de chargement d'un catalogue éditorial résilient.
enum EditorialCatalogLoadState {
  /// Aucun préchargement lancé.
  idle,

  /// Fetch distant en cours.
  loading,

  /// Cache distant renseigné (source primaire).
  readyRemote,

  /// Préchargement terminé sans données distantes — catalogue local actif.
  readyLocalFallback,
}
