import '../domain/models/favorite_record.dart';

/// État local des favoris et métadonnées de synchronisation.
class FavoritesLocalSnapshot {
  const FavoritesLocalSnapshot({
    required this.records,
    this.syncPending = false,
  });

  final List<FavoriteRecord> records;
  final bool syncPending;

  List<FavoriteRecord> get activeRecords =>
      records.where((record) => record.isActive).toList(growable: false);
}
