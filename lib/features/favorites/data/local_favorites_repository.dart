import '../domain/favorite_entity_type.dart';
import '../domain/favorites_repository.dart';
import '../domain/models/favorite_key.dart';
import '../domain/models/favorite_record.dart';
import 'favorite_validator.dart';
import 'favorites_preferences_store.dart';

/// Favoris locaux uniquement — repli permanent hors ligne.
class LocalFavoritesRepository extends FavoritesRepository {
  LocalFavoritesRepository({
    FavoritesPreferencesStore? store,
  })  : _store = store ?? const FavoritesPreferencesStore(),
        super.base();

  final FavoritesPreferencesStore _store;

  Set<FavoriteKey> _activeFavorites = const {};
  bool _isLoaded = false;

  @override
  Set<FavoriteKey> get activeFavorites => _activeFavorites;

  @override
  bool get isLoaded => _isLoaded;

  @override
  bool isFavorite({
    required FavoriteEntityType entityType,
    required String entitySlug,
  }) {
    return _activeFavorites.contains(
      FavoriteKey(entityType: entityType, entitySlug: entitySlug),
    );
  }

  @override
  Future<void> load() async {
    final snapshot = await _store.loadSnapshot();
    _activeFavorites = {
      for (final record in snapshot.activeRecords) record.key,
    };
    _isLoaded = true;
    notifyListeners();
  }

  @override
  Future<bool> addFavorite({
    required FavoriteEntityType entityType,
    required String entitySlug,
  }) async {
    final sanitizedSlug = FavoriteValidator.sanitizeSlug(entitySlug);
    if (!FavoriteValidator.isValidFavorite(
      entityType: entityType,
      entitySlug: sanitizedSlug,
    )) {
      return false;
    }

    final key = FavoriteKey(entityType: entityType, entitySlug: sanitizedSlug);
    if (_activeFavorites.contains(key)) return true;

    final snapshot = await _store.loadSnapshot();
    final now = DateTime.now().toUtc();
    final records = _upsertRecord(
      snapshot.records,
      FavoriteRecord(
        entityType: entityType,
        entitySlug: sanitizedSlug,
        isActive: true,
        updatedAt: now,
      ),
    );

    await _store.saveRecords(records);
    _activeFavorites = {..._activeFavorites, key};
    notifyListeners();
    return true;
  }

  @override
  Future<bool> removeFavorite({
    required FavoriteEntityType entityType,
    required String entitySlug,
  }) async {
    final sanitizedSlug = FavoriteValidator.sanitizeSlug(entitySlug);
    if (!FavoriteValidator.isValidFavorite(
      entityType: entityType,
      entitySlug: sanitizedSlug,
    )) {
      return false;
    }

    final key = FavoriteKey(entityType: entityType, entitySlug: sanitizedSlug);
    if (!_activeFavorites.contains(key)) return true;

    final snapshot = await _store.loadSnapshot();
    final now = DateTime.now().toUtc();
    final records = _upsertRecord(
      snapshot.records,
      FavoriteRecord(
        entityType: entityType,
        entitySlug: sanitizedSlug,
        isActive: false,
        updatedAt: now,
      ),
    );

    await _store.saveRecords(records);
    _activeFavorites = {..._activeFavorites}..remove(key);
    notifyListeners();
    return true;
  }

  @override
  Future<bool> toggleFavorite({
    required FavoriteEntityType entityType,
    required String entitySlug,
  }) {
    if (isFavorite(entityType: entityType, entitySlug: entitySlug)) {
      return removeFavorite(entityType: entityType, entitySlug: entitySlug);
    }
    return addFavorite(entityType: entityType, entitySlug: entitySlug);
  }

  static List<FavoriteRecord> _upsertRecord(
    List<FavoriteRecord> records,
    FavoriteRecord candidate,
  ) {
    final updated = [
      for (final record in records)
        if (record.key != candidate.key) record,
      candidate,
    ];
    return updated;
  }
}
