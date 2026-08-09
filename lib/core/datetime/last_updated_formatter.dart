/// Formate le libellé « dernière mise à jour » du tableau de bord.
abstract final class LastUpdatedFormatter {
  /// Retourne le libellé basé sur le fetch le plus récent.
  ///
  /// Chaîne vide s'il n'y a encore aucun fetch réel (pas de faux « il y a X min »).
  static String format(Iterable<DateTime?> fetchTimes) {
    final timestamps = fetchTimes.whereType<DateTime>().toList();
    if (timestamps.isEmpty) {
      return '';
    }

    timestamps.sort();
    final latest = timestamps.last;
    final difference = DateTime.now().difference(latest);

    if (difference.inMinutes < 1) {
      return 'Toutes les données mises à jour à l\'instant';
    }
    if (difference.inMinutes < 60) {
      return 'Toutes les données mises à jour il y a ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      return 'Toutes les données mises à jour il y a ${difference.inHours} h';
    }
    return 'Toutes les données mises à jour il y a ${difference.inDays} j';
  }
}
