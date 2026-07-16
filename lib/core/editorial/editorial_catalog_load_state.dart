/// État de chargement d'un catalogue éditorial résilient.
enum EditorialCatalogLoadState {
  /// Aucun préchargement lancé — le local est déjà disponible.
  idle,

  /// Fetch distant en cours (le local reste servi).
  loading,

  /// Cache distant renseigné (source primaire).
  success,

  /// Distant vide — catalogue local conservé (données potentiellement périmées).
  stale,

  /// Fetch distant en échec — catalogue local en repli.
  error,
}
