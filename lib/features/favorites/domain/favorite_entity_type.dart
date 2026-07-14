/// Type d'entité pouvant être mise en favori.
enum FavoriteEntityType {
  price,
  procedure,
  place,
}

/// Libellés persistés côté Supabase.
abstract final class FavoriteEntityTypeLabels {
  static const _fromStorage = {
    'price': FavoriteEntityType.price,
    'procedure': FavoriteEntityType.procedure,
    'place': FavoriteEntityType.place,
  };

  static FavoriteEntityType fromStorage(String? value) {
    return _fromStorage[value] ?? FavoriteEntityType.place;
  }

  static String toStorage(FavoriteEntityType type) => type.name;
}
