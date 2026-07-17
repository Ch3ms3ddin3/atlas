import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/editorial/editorial_catalog_load_state.dart';
import '../../../../core/location/geolocator_service.dart';
import '../../../../core/location/location_constants.dart';
import '../../../../core/location/location_repository.dart';
import '../../../../core/location/morocco_cities.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_empty_state.dart';
import '../../../../design_system/widgets/atlas_filter_chip.dart';
import '../../../explorer/data/resilient_place_repository.dart';
import '../../../explorer/domain/place_browse_filters.dart';
import '../../../explorer/domain/place_repository.dart';
import '../../../explorer/presentation/widgets/place_catalog_status_indicator.dart';
import '../../../explorer/presentation/widgets/place_category_filter.dart';
import '../../../explorer/presentation/widgets/place_city_filter.dart';
import '../../../favorites/domain/favorites_repository.dart';
import '../../../favorites/presentation/favorites_scope.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/domain/profile_repository.dart';
import '../../../profile/presentation/profile_scope.dart';
import '../../data/map_place_query.dart';
import '../../domain/atlas_map_models.dart';
import '../widgets/atlas_flutter_map_view.dart';
import '../widgets/place_map_preview_sheet.dart';

/// Carte interactive Atlas — lieux curatés avec coordonnées valides uniquement.
class AtlasMapPage extends StatefulWidget {
  const AtlasMapPage({
    super.key,
    this.isActive = true,
  });

  /// `false` tant que l'onglet Carte n'a pas été ouvert (évite tuiles/warmUp en fond).
  final bool isActive;

  @override
  State<AtlasMapPage> createState() => _AtlasMapPageState();
}

class _AtlasMapPageState extends State<AtlasMapPage> {
  final PlaceRepository _repository = PlaceRepository();
  final LocationRepository _locationRepository = LocationRepository();
  final GeolocatorService _geolocator = const GeolocatorService();
  final PlaceBrowseFilters _filters = PlaceBrowseFilters.instance;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  final AtlasMapTileProvider _tileProvider = const OsmAtlasMapTileProvider();

  List<AtlasMapMarker> _markers = const [];
  EditorialCatalogLoadState _loadState = EditorialCatalogLoadState.idle;
  ProfileRepository? _profileRepository;
  FavoritesRepository? _favoritesRepository;
  VoidCallback? _catalogListener;
  Timer? _searchDebounce;
  bool _hasLocationPermission = false;
  double? _userLat;
  double? _userLng;
  bool _tilesUnavailable = false;
  bool _mapEngineReady = false;

  @override
  void initState() {
    super.initState();
    if (_filters.cityName.isEmpty) {
      _filters.setCityName(LocationConstants.fallbackCity, notify: false);
    }
    _searchController.text = _filters.searchText;
    _searchController.addListener(_onSearchChanged);
    _filters.addListener(_onFiltersChanged);
    if (widget.isActive) {
      _activateMapEngine();
    }
  }

  @override
  void didUpdateWidget(AtlasMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _activateMapEngine();
    }
  }

  void _activateMapEngine() {
    if (_mapEngineReady) return;
    _mapEngineReady = true;
    _attachCatalogListener();
    _rebuildMarkers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _centerOnSelectedCity();
      unawaited(_checkPermission());
      unawaited(_repository.warmUp());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = ProfileScope.of(context);
    if (!identical(profile, _profileRepository)) {
      _profileRepository = profile;
      if (_filters.cityName.isEmpty ||
          _filters.cityName == LocationConstants.fallbackCity) {
        final preferred = MoroccoCities.resolve(profile.profile.preferredCity)
                ?.name ??
            LocationConstants.fallbackCity;
        _filters.setCityName(preferred);
      }
    }
    final favorites = FavoritesScope.of(context);
    if (!identical(favorites, _favoritesRepository)) {
      _favoritesRepository?.removeListener(_onFavoritesChanged);
      _favoritesRepository = favorites;
      _favoritesRepository?.addListener(_onFavoritesChanged);
      _rebuildMarkers();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _filters.removeListener(_onFiltersChanged);
    _favoritesRepository?.removeListener(_onFavoritesChanged);
    if (_mapEngineReady) {
      _detachCatalogListener();
    }
    _mapController.dispose();
    super.dispose();
  }

  void _attachCatalogListener() {
    final repository = _repository;
    if (repository is Listenable) {
      _catalogListener = _onCatalogChanged;
      (repository as Listenable).addListener(_catalogListener!);
    }
    _syncLoadState();
  }

  void _detachCatalogListener() {
    final repository = _repository;
    if (repository is Listenable && _catalogListener != null) {
      (repository as Listenable).removeListener(_catalogListener!);
    }
  }

  void _onCatalogChanged() {
    if (!mounted || !_mapEngineReady) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _syncLoadState();
        _rebuildMarkers(notify: false);
      });
    });
  }

  void _onFavoritesChanged() {
    if (!mounted || !_mapEngineReady) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _rebuildMarkers(notify: false));
    });
  }

  void _onFiltersChanged() {
    if (!mounted) return;
    if (_searchController.text != _filters.searchText) {
      _searchController.value = TextEditingValue(
        text: _filters.searchText,
        selection: TextSelection.collapsed(offset: _filters.searchText.length),
      );
    }
    setState(() {
      _rebuildMarkers(notify: false);
    });
    if (_mapEngineReady) {
      _centerOnSelectedCity();
    }
  }

  void _syncLoadState() {
    final repository = _repository;
    if (repository is ResilientPlaceRepository) {
      _loadState = repository.loadState;
    } else {
      _loadState = EditorialCatalogLoadState.idle;
    }
  }

  void _rebuildMarkers({bool notify = true}) {
    void update() {
      _markers = MapPlaceQuery.markers(
        repository: _repository,
        filters: _filters,
        favorites: _favoritesRepository,
      );
    }

    if (notify) {
      setState(update);
    } else {
      update();
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), () {
      _filters.setSearchText(_searchController.text);
    });
  }

  void _centerOnSelectedCity() {
    final city = MoroccoCities.resolve(_filters.cityName) ?? MoroccoCities.fallback;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(LatLng(city.latitude, city.longitude), 12);
      } catch (_) {
        // Contrôleur pas encore attaché.
      }
    });
  }

  Future<void> _checkPermission() async {
    final permission = await _geolocator.hasGrantedPermission();
    if (!mounted) return;
    setState(() => _hasLocationPermission = permission);
  }

  Future<void> _onNearMe() async {
    final preferred = _profileRepository?.profile.preferredCity ??
        UserProfile.defaultPreferredCity;
    final location = await _locationRepository.resolveLocation(
      preferredCityName: preferred,
    );
    if (!mounted) return;
    if (!location.isFromGps) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position indisponible — carte centrée sur la ville.'),
        ),
      );
      _centerOnSelectedCity();
      return;
    }
    setState(() {
      _userLat = location.latitude;
      _userLng = location.longitude;
      _hasLocationPermission = true;
    });
    _mapController.move(
      LatLng(location.latitude, location.longitude),
      14,
    );
  }

  Future<void> _onRefresh() async {
    await _repository.warmUp();
    await _checkPermission();
    if (!mounted) return;
    setState(() {
      _syncLoadState();
      _rebuildMarkers(notify: false);
      _tilesUnavailable = false;
    });
  }

  void _onMarkerTap(AtlasMapMarker marker) {
    final place = _repository.findById(marker.placeId);
    if (place == null) return;
    unawaited(showPlaceMapPreviewSheet(context, place: place));
  }

  AtlasMapCamera get _camera {
    final city = MoroccoCities.resolve(_filters.cityName) ?? MoroccoCities.fallback;
    return AtlasMapCamera(
      latitude: city.latitude,
      longitude: city.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AtlasSpacing.xl,
              AtlasSpacing.lg,
              AtlasSpacing.xl,
              AtlasSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Carte',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_hasLocationPermission)
                      IconButton(
                        tooltip: 'Près de moi',
                        onPressed: _onNearMe,
                        icon: const Icon(Icons.my_location_outlined),
                      ),
                  ],
                ),
                PlaceCatalogStatusIndicator(loadState: _loadState),
                if (_tilesUnavailable)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AtlasSpacing.sm),
                    child: Text(
                      'Tuiles indisponibles — marqueurs issus du cache.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un lieu…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Effacer',
                            onPressed: () {
                              _searchController.clear();
                              _filters.setSearchText('');
                            },
                            icon: const Icon(Icons.close, size: 20),
                          ),
                  ),
                ),
                const SizedBox(height: AtlasSpacing.md),
                PlaceCityFilter(
                  selectedCity: _filters.cityName.isEmpty
                      ? LocationConstants.fallbackCity
                      : _filters.cityName,
                  onCitySelected: (city) => _filters.setCityName(city),
                ),
                const SizedBox(height: AtlasSpacing.sm),
                PlaceCategoryFilter(
                  selectedCategory: _filters.category,
                  onCategorySelected: (category) {
                    if (category == null) {
                      _filters.update(clearCategory: true);
                    } else {
                      _filters.setCategory(category);
                    }
                  },
                ),
                const SizedBox(height: AtlasSpacing.sm),
                AtlasFilterChip(
                  label: 'Favoris',
                  isSelected: _filters.favoritesOnly,
                  onTap: () =>
                      _filters.setFavoritesOnly(!_filters.favoritesOnly),
                ),
              ],
            ),
          ),
          Expanded(
            child: !_mapEngineReady
                ? Center(
                    child: Text(
                      'Ouvrez cet onglet pour charger la carte.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AtlasFlutterMapView(
                            camera: _camera,
                            markers: _markers,
                            tileProvider: _tileProvider,
                            mapController: _mapController,
                            onMarkerTap: _onMarkerTap,
                            userLatitude: _userLat,
                            userLongitude: _userLng,
                          ),
                        ),
                        if (_loadState == EditorialCatalogLoadState.error &&
                            _markers.isEmpty)
                          const Align(
                            alignment: Alignment.center,
                            child: Material(
                              color: Colors.transparent,
                              child: AtlasEmptyState(
                                icon: Icons.map_outlined,
                                message:
                                    'Carte indisponible pour le moment. '
                                    'Tirez pour réessayer.',
                              ),
                            ),
                          )
                        else if (_markers.isEmpty)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: EdgeInsets.all(
                                isWide ? AtlasSpacing.xxl : AtlasSpacing.xl,
                              ),
                              child: Material(
                                elevation: 2,
                                borderRadius: BorderRadius.circular(12),
                                color: theme.colorScheme.surface,
                                child: const Padding(
                                  padding: EdgeInsets.all(AtlasSpacing.lg),
                                  child: Text(
                                    'Aucun lieu avec coordonnées vérifiées '
                                    'pour ces filtres.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Ouvre la carte en push (depuis Explorer ou ailleurs).
Future<void> openAtlasMap(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => const Scaffold(
        body: AtlasMapPage(),
      ),
    ),
  );
}
