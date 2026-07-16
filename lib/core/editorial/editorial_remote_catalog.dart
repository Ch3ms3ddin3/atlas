/// Lecture distante en lecture seule d'un catalogue éditorial (ex. Supabase).
abstract interface class EditorialRemoteCatalog<T> {
  /// Retourne les entrées publiées, ou lève en cas d'indisponibilité.
  Future<List<T>> fetchAll();
}
