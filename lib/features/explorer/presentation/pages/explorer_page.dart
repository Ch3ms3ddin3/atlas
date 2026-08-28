import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/editorial/editorial_catalog_load_state.dart';
import '../../../../core/location/location_constants.dart';
import '../../../../core/location/location_repository.dart';
import '../../../../core/location/morocco_cities.dart';
import '../../../../design_system/navigation/atlas_page_route.dart';
import '../../../../design_system/theme/atlas_motion.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_empty_state.dart';
import '../../../../design_system/widgets/atlas_reveal.dart';
import '../../../favorites/domain/favorite_entity_type.dart';
import '../../../favorites/domain/favorites_repository.dart';
import '../../../favorites/presentation/favorites_page_wrapper.dart';
import '../../../favorites/presentation/favorites_scope.dart';
import '../../../home/presentation/widgets/home_section_header.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/domain/profile_repository.dart';
import '../../../profile/presentation/profile_scope.dart';
import '../../../shell/presentation/shell_navigation_scope.dart';
import '../../../shell/presentation/shell_tab_scroll_binding.dart';
import '../../data/place_mapper.dart';
import '../../data/resilient_place_repository.dart';
import '../../domain/models/place_models.dart';
import '../../domain/place_browse_filters.dart';
import '../../domain/place_repository.dart';
import '../pages/place_detail_page.dart';
import '../widgets/explorer_empty_state.dart';
import '../widgets/explorer_hero.dart';
import '../widgets/explorer_search_field.dart';
import '../widgets/place_featured_card.dart';
import '../widgets/place_guide_card_skeleton.dart';
import '../widgets/place_catalog_status_indicator.dart';
import '../widgets/place_category_filter.dart';
import '../widgets/place_city_filter.dart';
import '../widgets/place_guide_card.dart';
import '../widgets/place_sort_button.dart';

/// Répond à : « Que puis-je découvrir autour de moi ? »
class ExplorerPage extends StatefulWidget {
  const ExplorerPage({super.key});

  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends State<ExplorerPage>
    with ShellTabScrollBinding {
  static const _searchDebounce = Duration(milliseconds: 200);
  static const _wideBreakpoint = 720.0;

  final PlaceRepository _repository = PlaceRepository();
  final LocationRepository _locationRepository = LocationRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final PlaceBrowseFilters _browseFilters = PlaceBrowseFilters.instance;

  @override
  int get shellTabIndex => AtlasShellTab.explorer;

  @override
  ScrollController get tabScrollController => _scrollController;

  String _cityName = LocationConstants.fallbackCity;
  bool _isCityCovered = true;
  PlaceCategory? _selectedCategory;
  PlaceSort _sort = PlaceSort.catalog;
  List<PlaceGuide> _places = const [];
  ProfileRepository? _profileRepository;
  FavoritesRepository? _favoritesRepository;
  Timer? _searchDebounceTimer;
  VoidCallback? _catalogListener;
  EditorialCatalogLoadState _loadState = EditorialCatalogLoadState.idle;
  int _locationRequestId = 0;
  bool _syncingFromSharedFilters = false;

  @override
  void initState() {
    super.initState();
    _cityName = _browseCityFor(
      _browseFilters.cityName.isNotEmpty
          ? _canonicalSupportedCity(_browseFilters.cityName)
          : _canonicalSupportedCity(_repository.resolveCityName(null)),
    );
    _selectedCategory = _browseFilters.category;
    _searchController.text = _browseFilters.searchText;
    _browseFilters.setCityName(_cityName, notify: false);
    _isCityCovered = _repository.isCityCovered(_cityName);
    _attachCatalogListener();
    _browseFilters.addListener(_onSharedFiltersChanged);
    _applyFilters();
    _searchController.addListener(_onSearchTextChanged);
    _searchFocus.addListener(() {
      if (mounted) setState(() {});
    });
    // La localisation suit l'attachement du profil dans didChangeDependencies.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bindShellTabScroll();
    final repository = ProfileScope.of(context);
    if (!identical(repository, _profileRepository)) {
      _profileRepository?.removeListener(_onProfileChanged);
      _profileRepository = repository;
      _profileRepository!.addListener(_onProfileChanged);
      if (repository.isLoaded) {
        unawaited(_resolveLocation());
      }
    }
    final favorites = FavoritesScope.of(context);
    if (!identical(favorites, _favoritesRepository)) {
      _favoritesRepository?.removeListener(_onFavoritesChanged);
      _favoritesRepository = favorites;
      _favoritesRepository?.addListener(_onFavoritesChanged);
      _applyFilters();
    }
  }

  @override
  void dispose() {
    unbindShellTabScroll();
    _searchDebounceTimer?.cancel();
    _profileRepository?.removeListener(_onProfileChanged);
    _favoritesRepository?.removeListener(_onFavoritesChanged);
    _browseFilters.removeListener(_onSharedFiltersChanged);
    _detachCatalogListener();
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSharedFiltersChanged() {
    if (!mounted || _syncingFromSharedFilters) return;
    setState(() {
      _cityName = _browseFilters.cityName.isEmpty
          ? _cityName
          : _browseCityFor(_canonicalSupportedCity(_browseFilters.cityName));
      _selectedCategory = _browseFilters.category;
      if (_searchController.text != _browseFilters.searchText) {
        _searchController.value = TextEditingValue(
          text: _browseFilters.searchText,
          selection: TextSelection.collapsed(
            offset: _browseFilters.searchText.length,
          ),
        );
      }
      _applyFilters(notify: false);
    });
  }

  void _onFavoritesChanged() {
    if (!mounted) return;
    setState(() => _applyFilters(notify: false));
  }

  void _pushSharedFilters() {
    _syncingFromSharedFilters = true;
    _browseFilters.update(
      cityName: _cityName,
      category: _selectedCategory,
      clearCategory: _selectedCategory == null,
      searchText: _searchController.text,
    );
    _syncingFromSharedFilters = false;
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
    if (!mounted) return;
    setState(() {
      _syncLoadState();
      _applyFilters(notify: false);
    });
  }

  void _syncLoadState() {
    final repository = _repository;
    if (repository is ResilientPlaceRepository) {
      _loadState = repository.loadState;
    } else {
      _loadState = EditorialCatalogLoadState.idle;
    }
  }

  void _onProfileChanged() {
    if (!mounted) return;
    unawaited(_resolveLocation());
  }

  void _applyContentCity(String cityName) {
    final preferred = _browseCityFor(_canonicalSupportedCity(cityName));
    setState(() {
      _cityName = preferred;
      _isCityCovered = _repository.isCityCovered(_cityName);
      _pushSharedFilters();
      _applyFilters(notify: false);
    });
  }

  void _onSearchTextChanged() {
    setState(() {});
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      // Appliquer d'abord (déduit la catégorie depuis le texte), puis synchroniser.
      _applyFilters(resetScroll: true);
      _pushSharedFilters();
    });
  }

  Future<void> _resolveLocation() async {
    final requestId = ++_locationRequestId;
    final profile = _profileRepository?.profile ?? UserProfile.defaults;
    final location = await _locationRepository.resolveForProfile(profile);
    if (!mounted || requestId != _locationRequestId) return;

    _applyContentCity(location.catalogCity);
  }

  String _canonicalSupportedCity(String cityName) {
    final match = MoroccoCities.resolve(cityName);
    return match?.name ?? LocationConstants.fallbackCity;
  }

  /// Beta : puces limitées aux villes couvertes — repli Marrakech si besoin.
  String _browseCityFor(String cityName) {
    if (_repository.isCityCovered(cityName)) return cityName;
    return LocationConstants.fallbackCity;
  }

  List<String> get _coveredCityNames => [
    for (final name in MoroccoCities.supportedNames)
      if (_repository.isCityCovered(name)) name,
  ];

  void _applyFilters({bool notify = true, bool resetScroll = false}) {
    void update() {
      _isCityCovered = _repository.isCityCovered(_cityName);
      final available = _availableCategoriesForCity(_cityName);
      if (_selectedCategory != null && !available.contains(_selectedCategory)) {
        _selectedCategory = null;
      }
      // « restaurant » (etc.) prime sur une puce catégorie conflictuelle restante
      // (ex. Hammam encore active après la Phase 2 / filtres partagés Carte).
      final inferredCategory = PlaceMapper.categoryMatchingSearch(
        _searchController.text,
      );
      if (inferredCategory != null && available.contains(inferredCategory)) {
        _selectedCategory = inferredCategory;
      }
      var places = _repository.search(
        PlaceSearchQuery(
          text: _searchController.text,
          category: _selectedCategory,
          cityName: _cityName,
          sort: _sort,
          strictCity: true,
        ),
      );
      if (_browseFilters.favoritesOnly) {
        final favorites = _favoritesRepository;
        places = places
            .where(
              (place) =>
                  favorites != null &&
                  favorites.isLoaded &&
                  favorites.isFavorite(
                    entityType: FavoriteEntityType.place,
                    entitySlug: place.id,
                  ),
            )
            .toList();
      }
      _places = places;
    }

    if (notify) {
      setState(update);
    } else {
      update();
    }
    if (resetScroll) {
      _resetExplorerScroll();
    }
  }

  void _resetExplorerScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
  }

  List<PlaceCategory> _availableCategoriesForCity(String cityName) {
    if (!_repository.isCityCovered(cityName)) return const [];
    return PlaceMapper.categoriesPresentIn(
      _repository.getAll(cityName: cityName),
    );
  }

  void _onCitySelected(String city) {
    setState(() {
      _cityName = city;
      _pushSharedFilters();
      _applyFilters(notify: false);
    });
  }

  void _onCategorySelected(PlaceCategory? category) {
    setState(() {
      _selectedCategory = category;
      _pushSharedFilters();
      _applyFilters(notify: false);
    });
  }

  void _onSortSelected(PlaceSort sort) {
    setState(() {
      _sort = sort;
      _applyFilters(notify: false);
    });
  }

  void _clearSearchAndFilters() {
    _searchController.clear();
    setState(() {
      _selectedCategory = null;
      _sort = PlaceSort.catalog;
      _browseFilters.setFavoritesOnly(false, notify: false);
      _pushSharedFilters();
      _applyFilters(notify: false);
    });
  }

  void _openPlace(PlaceGuide place) {
    Navigator.of(context).push(
      AtlasPageRoute<void>(
        page: PlaceDetailPage(place: place, placeId: place.id),
        wrapPage: (child) => wrapWithFavoritesScope(context, child),
      ),
    );
  }

  Future<void> _onRefresh() async {
    final repository = _repository;
    if (repository is ResilientPlaceRepository) {
      // Réessaie le distant après erreur/timeout (warmUp rejouable).
      await repository.warmUp();
      await _resolveLocation();
    } else {
      await _resolveLocation();
    }
    if (!mounted) return;
    setState(() {
      _syncLoadState();
      _applyFilters(notify: false);
    });
  }

  PlaceGuide? get _featuredPlace {
    if (!_isCityCovered || _places.isEmpty) return null;
    final featured = _repository.getFeatured(cityName: _cityName, limit: 1);
    if (featured.isEmpty) return null;
    final candidate = featured.first;
    if (!_places.any((place) => place.id == candidate.id)) return null;
    return candidate;
  }

  List<PlaceGuide> get _listPlaces {
    final featured = _featuredPlace;
    if (featured == null) return _places;
    return _places.where((place) => place.id != featured.id).toList();
  }

  bool get _isLoadingCatalog => _loadState == EditorialCatalogLoadState.loading;

  void _showDirectionsSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir l\'itinéraire pour ce lieu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters =
        _searchController.text.trim().isNotEmpty ||
        _selectedCategory != null ||
        _sort != PlaceSort.catalog ||
        _browseFilters.favoritesOnly;
    final featuredPlace = _featuredPlace;
    final listPlaces = _listPlaces;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: AtlasContentContainer(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useGrid = constraints.maxWidth >= _wideBreakpoint;

              return CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AtlasSpacing.lg),
                        AtlasReveal(
                          child: ExplorerHero(
                            onMapTap: () =>
                                ShellNavigationScope.goToMap(context),
                          ),
                        ),
                        if (!_isCityCovered) ...[
                          const SizedBox(height: AtlasSpacing.sm),
                          Text(
                            'Contenu bientôt disponible pour $_cityName.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                        const SizedBox(height: AtlasSpacing.lg),
                        PlaceCatalogStatusIndicator(loadState: _loadState),
                        const SizedBox(height: AtlasSpacing.lg),
                        ExplorerSearchField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onChanged: _onSearchTextChanged,
                          onClear: () {
                            _searchController.clear();
                            _applyFilters(resetScroll: true);
                            _pushSharedFilters();
                          },
                        ),
                        const SizedBox(height: AtlasSpacing.md),
                        AtlasReveal(
                          delay: AtlasMotion.staggerDelay,
                          child: PlaceCityFilter(
                            selectedCity: _cityName,
                            cities: _coveredCityNames,
                            onCitySelected: _onCitySelected,
                          ),
                        ),
                        const SizedBox(height: AtlasSpacing.xs),
                        AtlasReveal(
                          delay: AtlasMotion.staggerDelay * 2,
                          child: PlaceCategoryFilter(
                            selectedCategory: _selectedCategory,
                            availableCategories: _availableCategoriesForCity(
                              _cityName,
                            ),
                            onCategorySelected: _onCategorySelected,
                            favoritesOnly: _browseFilters.favoritesOnly,
                            onFavoritesToggle: () {
                              _browseFilters.setFavoritesOnly(
                                !_browseFilters.favoritesOnly,
                              );
                              _applyFilters();
                            },
                          ),
                        ),
                        if (featuredPlace != null && !_isLoadingCatalog) ...[
                          const SizedBox(height: AtlasSpacing.section),
                          AtlasReveal(
                            delay: AtlasMotion.staggerDelay * 3,
                            child: const HomeSectionHeader(
                              title: 'Sélection Atlas',
                            ),
                          ),
                          const SizedBox(height: AtlasSpacing.md),
                          AtlasReveal(
                            delay: AtlasMotion.staggerDelay * 4,
                            child: PlaceFeaturedCard(
                              place: featuredPlace,
                              onTap: () => _openPlace(featuredPlace),
                              onDirectionsFailed: _showDirectionsSnackBar,
                            ),
                          ),
                        ],
                        const SizedBox(height: AtlasSpacing.section),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: HomeSectionHeader(
                                title: _isCityCovered && listPlaces.isNotEmpty
                                    ? 'Lieux à découvrir · ${listPlaces.length}'
                                    : 'Lieux à découvrir',
                              ),
                            ),
                            if (_isCityCovered)
                              PlaceSortButton(
                                selectedSort: _sort,
                                onSortSelected: _onSortSelected,
                              ),
                          ],
                        ),
                        const SizedBox(height: AtlasSpacing.md),
                      ],
                    ),
                  ),
                  if (!_isCityCovered)
                    const SliverToBoxAdapter(
                      child: AtlasEmptyState(
                        icon: Icons.explore_outlined,
                        message:
                            'Contenu bientôt disponible pour cette ville. '
                            'Changez de ville pour continuer à explorer.',
                      ),
                    )
                  else if (_isLoadingCatalog)
                    SliverList.separated(
                      itemCount: 3,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AtlasSpacing.lg),
                      itemBuilder: (context, index) {
                        return PlaceGuideCardSkeleton(compact: useGrid);
                      },
                    )
                  else if (_places.isEmpty)
                    SliverToBoxAdapter(
                      child: ExplorerEmptyState(
                        onReset: hasActiveFilters
                            ? _clearSearchAndFilters
                            : null,
                      ),
                    )
                  else if (useGrid)
                    SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: AtlasSpacing.lg,
                            crossAxisSpacing: AtlasSpacing.lg,
                            childAspectRatio: 0.78,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final place = listPlaces[index];
                        return PlaceGuideCard(
                          place: place,
                          compact: true,
                          onTap: () => _openPlace(place),
                        );
                      }, childCount: listPlaces.length),
                    )
                  else
                    SliverList.separated(
                      itemCount: listPlaces.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AtlasSpacing.lg),
                      itemBuilder: (context, index) {
                        final place = listPlaces[index];
                        return PlaceGuideCard(
                          place: place,
                          onTap: () => _openPlace(place),
                        );
                      },
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AtlasSpacing.lg),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Ouvre un lieu depuis n'importe quel écran de l'application.
void openPlaceGuide(BuildContext context, PlaceGuide place) {
  Navigator.of(context).push(
    AtlasPageRoute<void>(
      page: PlaceDetailPage(place: place, placeId: place.id),
      wrapPage: (child) => wrapWithFavoritesScope(context, child),
    ),
  );
}

/// Ouvre un lieu par slug — affiche empty state si introuvable.
void openPlaceGuideById(
  BuildContext context,
  PlaceRepository repository,
  String placeId,
) {
  final place = repository.findById(placeId);
  Navigator.of(context).push(
    AtlasPageRoute<void>(
      page: PlaceDetailPage(
        place: place,
        placeId: placeId,
        repository: repository,
      ),
      wrapPage: (child) => wrapWithFavoritesScope(context, child),
    ),
  );
}
