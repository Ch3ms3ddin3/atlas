import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/editorial/editorial_catalog_load_state.dart';
import '../../../../core/location/location_constants.dart';
import '../../../../core/location/location_repository.dart';
import '../../../../design_system/navigation/atlas_page_route.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_empty_state.dart';
import '../../../../design_system/widgets/atlas_page_header.dart';
import '../../../favorites/presentation/favorites_page_wrapper.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/domain/profile_repository.dart';
import '../../../profile/presentation/profile_scope.dart';
import '../../../shell/presentation/shell_navigation_scope.dart';
import '../../../shell/presentation/shell_tab_scroll_binding.dart';
import '../../data/resilient_price_intelligence_repository.dart';
import '../../domain/models/price_observation.dart';
import '../../domain/price_intelligence_repository.dart';
import '../widgets/price_city_selector.dart';
import '../widgets/price_intelligence_category_filter.dart';
import '../widgets/price_intelligence_sort_button.dart';
import '../widgets/price_intelligence_status_indicator.dart';
import '../widgets/price_observation_card.dart';
import '../widgets/prices_scroll_progress_indicator.dart';
import 'price_observation_detail_page.dart';

/// Price Intelligence — données vérifiées uniquement, jamais inventées.
class PricesPage extends StatefulWidget {
  const PricesPage({super.key});

  @override
  State<PricesPage> createState() => _PricesPageState();
}

class _PricesPageState extends State<PricesPage> with ShellTabScrollBinding {
  static const _wideBreakpoint = 840.0;

  final PriceIntelligenceRepository _repository = PriceIntelligenceRepository();
  final LocationRepository _locationRepository = LocationRepository();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  int get shellTabIndex => AtlasShellTab.prices;

  @override
  ScrollController get tabScrollController => _scrollController;

  String _cityName = LocationConstants.fallbackCity;
  PriceIntelligenceCategory? _selectedCategory;
  PriceIntelligenceSort _sort = PriceIntelligenceSort.atlasRecommendation;
  List<PriceObservation> _items = const [];
  ProfileRepository? _profileRepository;
  EditorialCatalogLoadState _loadState = EditorialCatalogLoadState.idle;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _syncLoadState();
    if (_repository is Listenable) {
      (_repository as Listenable).addListener(_onRepoChanged);
    }
    _searchController.addListener(_onSearchChanged);
    unawaited(_repository.warmUp());
    _applyFilters();
    unawaited(_resolveLocation());
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
      unawaited(_resolveLocation());
    }
  }

  @override
  void dispose() {
    unbindShellTabScroll();
    _searchDebounce?.cancel();
    _profileRepository?.removeListener(_onProfileChanged);
    if (_repository is Listenable) {
      (_repository as Listenable).removeListener(_onRepoChanged);
    }
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (!mounted) return;
    setState(() {
      _syncLoadState();
      _applyFilters(notify: false);
    });
  }

  void _syncLoadState() {
    final repository = _repository;
    if (repository is ResilientPriceIntelligenceRepository) {
      _loadState = repository.loadState;
    } else {
      _loadState = EditorialCatalogLoadState.idle;
    }
  }

  void _onProfileChanged() {
    if (!mounted) return;
    unawaited(_resolveLocation());
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _applyFilters();
    });
  }

  Future<void> _resolveLocation() async {
    final profile = _profileRepository?.profile ?? UserProfile.defaults;
    final location = await _locationRepository.resolveForProfile(profile);
    if (!mounted) return;
    setState(() {
      _cityName = location.catalogCity;
      _applyFilters(notify: false);
    });
  }

  void _applyFilters({bool notify = true}) {
    void update() {
      final available = _repository.categories;
      if (_selectedCategory != null && !available.contains(_selectedCategory)) {
        _selectedCategory = null;
      }
      _items = _repository.search(
        PriceIntelligenceQuery(
          text: _searchController.text,
          category: _selectedCategory,
          cityName: _cityName,
          sort: _sort,
        ),
      );
    }

    if (notify) {
      setState(update);
    } else {
      update();
    }
  }

  Future<void> _onRefresh() => _repository.refresh();

  void _openObservation(PriceObservation observation) {
    openPriceObservation(context, observation);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= _wideBreakpoint;
    final cities = _repository.availableCities;
    final showUnavailable =
        _loadState == EditorialCatalogLoadState.error &&
        _items.isEmpty &&
        _repository.getAll().isEmpty;

    final contentRevision = Object.hash(
      _items.length,
      _cityName,
      _selectedCategory,
      _searchController.text,
      _sort,
      _loadState,
    );

    return SafeArea(
      child: AtlasContentContainer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                controller: _scrollController,
                key: const PageStorageKey<String>('prices_scroll'),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AtlasSpacing.xxl),
                        AtlasPageHeader(
                          title: 'Prix',
                          subtitle: _headerSubtitle,
                        ),
                        const SizedBox(height: AtlasSpacing.md),
                        PriceIntelligenceStatusIndicator(loadState: _loadState),
                        const SizedBox(height: AtlasSpacing.lg),
                        TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Rechercher un prix…',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: AtlasSpacing.lg),
                        PriceCitySelector(
                          selectedCity: _cityName,
                          dataCities: cities,
                          onCitySelected: (city) {
                            setState(() => _cityName = city);
                            _applyFilters();
                          },
                        ),
                        const SizedBox(height: AtlasSpacing.lg),
                        PriceIntelligenceCategoryFilter(
                          selectedCategory: _selectedCategory,
                          availableCategories: _repository.categories,
                          onCategorySelected: (category) {
                            setState(() => _selectedCategory = category);
                            _applyFilters();
                          },
                        ),
                        const SizedBox(height: AtlasSpacing.md),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: PriceIntelligenceSortButton(
                            sort: _sort,
                            onSortSelected: (sort) {
                              setState(() => _sort = sort);
                              _applyFilters();
                            },
                          ),
                        ),
                        const SizedBox(height: AtlasSpacing.xl),
                      ],
                    ),
                  ),
                  if (showUnavailable)
                    const SliverToBoxAdapter(
                      child: AtlasEmptyState(
                        icon: Icons.cloud_off_outlined,
                        message:
                            'Prix indisponibles pour le moment. '
                            'Tirez pour réessayer — aucune valeur inventée.',
                      ),
                    )
                  else if (_items.isEmpty)
                    SliverToBoxAdapter(
                      child: AtlasEmptyState(
                        icon: Icons.payments_outlined,
                        message: _emptyMessage,
                      ),
                    )
                  else if (isWide)
                    SliverPadding(
                      padding: const EdgeInsets.only(
                        bottom: AtlasSpacing.sectionLarge,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: AtlasSpacing.lg,
                              crossAxisSpacing: AtlasSpacing.lg,
                              childAspectRatio: 1.55,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = _items[index];
                          return PriceObservationCard(
                            observation: item,
                            onTap: () => _openObservation(item),
                          );
                        }, childCount: _items.length),
                      ),
                    )
                  else
                    SliverList.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AtlasSpacing.lg),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return PriceObservationCard(
                          observation: item,
                          onTap: () => _openObservation(item),
                        );
                      },
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AtlasSpacing.sectionLarge),
                  ),
                ],
              ),
            ),
            PricesScrollProgressIndicator(
              controller: _scrollController,
              contentRevision: contentRevision,
            ),
          ],
        ),
      ),
    );
  }

  String get _headerSubtitle {
    if (_cityName == LocationConstants.fallbackCity) {
      return 'Tarifs vérifiés pour Marrakech — billets culturels '
          'et monuments, plus forfaits mobile et internet '
          'nationaux. Aucune valeur inventée.';
    }
    return 'Tarifs vérifiés pour $_cityName lorsqu\'ils existent, '
        'plus forfaits nationaux applicables. '
        'Aucune valeur inventée.';
  }

  String get _emptyMessage {
    final hasFilters =
        _searchController.text.trim().isNotEmpty || _selectedCategory != null;
    if (hasFilters) {
      return 'Aucun prix vérifié ne correspond à ces filtres.';
    }
    return 'Pas encore de tarifs vérifiés pour $_cityName. '
        'Atlas n\'affiche que des tarifs sourcés — aucune valeur inventée.';
  }
}

/// Ouvre le détail d'une observation.
void openPriceObservation(BuildContext context, PriceObservation observation) {
  Navigator.of(context).push(
    AtlasPageRoute<void>(
      page: PriceObservationDetailPage(observation: observation),
      wrapPage: (child) => wrapWithFavoritesScope(context, child),
    ),
  );
}

/// Ouvre une observation par slug ; no-op si absente.
void openPriceObservationById(
  BuildContext context,
  PriceIntelligenceRepository repository,
  String priceId,
) {
  final observation = repository.findById(priceId);
  if (observation == null) return;
  openPriceObservation(context, observation);
}
