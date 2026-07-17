import 'package:flutter/foundation.dart';

import 'models/place_models.dart';

/// Filtres partagés Explorer ↔ Carte — synchro UI uniquement, pas de logique métier.
class PlaceBrowseFilters extends ChangeNotifier {
  PlaceBrowseFilters._();

  static final PlaceBrowseFilters instance = PlaceBrowseFilters._();

  String _cityName = '';
  PlaceCategory? _category;
  String _searchText = '';
  bool _favoritesOnly = false;

  String get cityName => _cityName;
  PlaceCategory? get category => _category;
  String get searchText => _searchText;
  bool get favoritesOnly => _favoritesOnly;

  void setCityName(String value, {bool notify = true}) {
    if (_cityName == value) return;
    _cityName = value;
    if (notify) notifyListeners();
  }

  void setCategory(PlaceCategory? value, {bool notify = true}) {
    if (_category == value) return;
    _category = value;
    if (notify) notifyListeners();
  }

  void setSearchText(String value, {bool notify = true}) {
    if (_searchText == value) return;
    _searchText = value;
    if (notify) notifyListeners();
  }

  void setFavoritesOnly(bool value, {bool notify = true}) {
    if (_favoritesOnly == value) return;
    _favoritesOnly = value;
    if (notify) notifyListeners();
  }

  void update({
    String? cityName,
    PlaceCategory? category,
    bool clearCategory = false,
    String? searchText,
    bool? favoritesOnly,
  }) {
    var changed = false;
    if (cityName != null && _cityName != cityName) {
      _cityName = cityName;
      changed = true;
    }
    if (clearCategory) {
      if (_category != null) {
        _category = null;
        changed = true;
      }
    } else if (category != null && _category != category) {
      _category = category;
      changed = true;
    }
    if (searchText != null && _searchText != searchText) {
      _searchText = searchText;
      changed = true;
    }
    if (favoritesOnly != null && _favoritesOnly != favoritesOnly) {
      _favoritesOnly = favoritesOnly;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  @visibleForTesting
  static void resetForTest() {
    instance._cityName = '';
    instance._category = null;
    instance._searchText = '';
    instance._favoritesOnly = false;
  }
}
