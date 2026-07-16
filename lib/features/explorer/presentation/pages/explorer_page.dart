import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/editorial/editorial_catalog_load_state.dart';
import '../../../../core/location/location_constants.dart';
import '../../../../core/location/location_repository.dart';
import '../../../../core/location/morocco_cities.dart';
import '../../../../design_system/navigation/atlas_page_route.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_empty_state.dart';
import '../../../../design_system/widgets/atlas_page_header.dart';
import '../../../favorites/presentation/favorites_page_wrapper.dart';
import '../../../home/presentation/widgets/home_section_header.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/domain/profile_repository.dart';
import '../../../profile/presentation/profile_scope.dart';
import '../../data/resilient_place_repository.dart';
import '../../domain/models/place_models.dart';
import '../../domain/place_repository.dart';
import '../pages/place_detail_page.dart';
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

class _ExplorerPageState extends State<ExplorerPage> {
  static const _searchDebounce = Duration(milliseconds: 200);
  static const _wideBreakpoint = 720.0;

  final PlaceRepository _repository = PlaceRepository();
  final LocationRepository _locationRepository = LocationRepository();
  final TextEditingController _searchController = TextEditingController();

  String _cityName = LocationConstants.fallbackCity;
  bool _isCityCovered = true;
  PlaceCategory? _selectedCategory;
  PlaceSort _sort = PlaceSort.catalog;
  List<PlaceGuide> _places = const [];
  ProfileRepository? _profileRepository;
  Timer? _searchDebounceTimer;
  VoidCallback? _catalogListener;
  EditorialCatalogLoadState _loadState = EditorialCatalogLoadState.idle;
  int _locationRequestId = 0;

  @override
  void initState() {
    super.initState();
    _cityName = _canonicalSupportedCity(
      _repository.resolveCityName(null),
    );
    _isCityCovered = _repository.isCityCovered(_cityName);
    _attachCatalogListener();
    _applyFilters();
    _searchController.addListener(_onSearchTextChanged);
    // La localisation suit l'attachement du profil dans didChangeDependencies.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = ProfileScope.of(context);
    if (!identical(repository, _profileRepository)) {
      _profileRepository?.removeListener(_onProfileChanged);
      _profileRepository = repository;
      _profileRepository!.addListener(_onProfileChanged);
      if (repository.isLoaded) {
        _applyPreferredCity(repository.profile.preferredCity);
        unawaited(_resolveLocation());
      }
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _profileRepository?.removeListener(_onProfileChanged);
    _detachCatalogListener();
    _searchController.dispose();
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
    _applyPreferredCity(_profileRepository!.profile.preferredCity);
    unawaited(_resolveLocation());
  }

  void _applyPreferredCity(String preferredCity) {
    final preferred = _canonicalSupportedCity(preferredCity);
    setState(() {
      _cityName = preferred;
      _isCityCovered = _repository.isCityCovered(_cityName);
      _applyFilters(notify: false);
    });
  }

  void _onSearchTextChanged() {
    setState(() {});
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      _applyFilters();
    });
  }

  Future<void> _resolveLocation() async {
    final requestId = ++_locationRequestId;
    final location = await _locationRepository.resolveLocation(
      preferredCityName: _profileRepository?.profile.preferredCity ??
          UserProfile.defaultPreferredCity,
    );
    if (!mounted || requestId != _locationRequestId) return;

    // Relire le profil après l'await — il peut s'attacher pendant le GPS.
    final preferredCity = _profileRepository?.profile.preferredCity ??
        location.cityName;
    final preferred = _canonicalSupportedCity(preferredCity);

    setState(() {
      _cityName = preferred;
      _isCityCovered = _repository.isCityCovered(_cityName);
      _applyFilters(notify: false);
    });
  }

  String _canonicalSupportedCity(String cityName) {
    final match = MoroccoCities.resolve(cityName);
    return match?.name ?? LocationConstants.fallbackCity;
  }

  void _applyFilters({bool notify = true}) {
    void update() {
      _isCityCovered = _repository.isCityCovered(_cityName);
      _places = _repository.search(
        PlaceSearchQuery(
          text: _searchController.text,
          category: _selectedCategory,
          cityName: _cityName,
          sort: _sort,
          strictCity: true,
        ),
      );
    }

    if (notify) {
      setState(update);
    } else {
      update();
    }
  }

  void _onCitySelected(String city) {
    setState(() {
      _cityName = city;
      _applyFilters(notify: false);
    });
  }

  void _onCategorySelected(PlaceCategory? category) {
    setState(() {
      _selectedCategory = category;
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
      _applyFilters(notify: false);
    });
  }

  void _openPlace(PlaceGuide place) {
    Navigator.of(context).push(
      AtlasPageRoute<void>(
        page: PlaceDetailPage(place: place),
        wrapPage: (child) => wrapWithFavoritesScope(context, child),
      ),
    );
  }

  Future<void> _onRefresh() async {
    final repository = _repository;
    if (repository is ResilientPlaceRepository) {
      // warmUp is idempotent after first call — re-apply filters + location.
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

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _searchController.text.trim().isNotEmpty ||
        _selectedCategory != null ||
        _sort != PlaceSort.catalog;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: AtlasContentContainer(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useGrid = constraints.maxWidth >= _wideBreakpoint;

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AtlasSpacing.xxl),
                        AtlasPageHeader(
                          title: 'Explorer',
                          subtitle:
                              'Lieux utiles à $_cityName — découvertes curatées par Atlas.',
                          footnote: _isCityCovered
                              ? null
                              : 'Contenu bientôt disponible pour $_cityName.',
                        ),
                        const SizedBox(height: AtlasSpacing.xl),
                        PlaceCatalogStatusIndicator(loadState: _loadState),
                        TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Rechercher un lieu…',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Effacer',
                                    onPressed: () {
                                      _searchController.clear();
                                      _applyFilters();
                                    },
                                    icon: const Icon(Icons.close, size: 20),
                                  ),
                          ),
                        ),
                        const SizedBox(height: AtlasSpacing.lg),
                        PlaceCityFilter(
                          selectedCity: _cityName,
                          onCitySelected: _onCitySelected,
                        ),
                        const SizedBox(height: AtlasSpacing.md),
                        PlaceCategoryFilter(
                          selectedCategory: _selectedCategory,
                          onCategorySelected: _onCategorySelected,
                        ),
                        const SizedBox(height: AtlasSpacing.xl),
                        Row(
                          children: [
                            Expanded(
                              child: HomeSectionHeader(
                                title: _isCityCovered && _places.isNotEmpty
                                    ? 'Lieux à découvrir · ${_places.length}'
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
                        const SizedBox(height: AtlasSpacing.lg),
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
                  else if (_places.isEmpty)
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const AtlasEmptyState(
                            message:
                                'Aucun lieu ne correspond à votre recherche.',
                          ),
                          if (hasActiveFilters)
                            TextButton(
                              onPressed: _clearSearchAndFilters,
                              child: const Text('Réinitialiser les filtres'),
                            ),
                        ],
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
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final place = _places[index];
                          return PlaceGuideCard(
                            place: place,
                            compact: true,
                            onTap: () => _openPlace(place),
                          );
                        },
                        childCount: _places.length,
                      ),
                    )
                  else
                    SliverList.separated(
                      itemCount: _places.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AtlasSpacing.lg),
                      itemBuilder: (context, index) {
                        final place = _places[index];
                        return PlaceGuideCard(
                          place: place,
                          onTap: () => _openPlace(place),
                        );
                      },
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AtlasSpacing.sectionLarge),
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
      page: PlaceDetailPage(place: place),
      wrapPage: (child) => wrapWithFavoritesScope(context, child),
    ),
  );
}

/// Ouvre un lieu par identifiant ; ne fait rien si introuvable.
void openPlaceGuideById(
  BuildContext context,
  PlaceRepository repository,
  String placeId,
) {
  final place = repository.findById(placeId);
  if (place == null) return;
  openPlaceGuide(context, place);
}
