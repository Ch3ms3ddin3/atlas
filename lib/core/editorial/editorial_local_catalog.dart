/// Catalogue éditorial local permanent (repli hors ligne).
///
/// Les implémentations exposent typiquement un catalogue Dart statique.
abstract interface class EditorialLocalCatalog<T> {
  /// Entrées locales garanties, non vides pour les catalogues MVP.
  List<T> get items;
}
