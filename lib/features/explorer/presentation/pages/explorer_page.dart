import 'package:flutter/material.dart';

import '../../../../core/location/location_repository.dart';
import '../../../../design_system/navigation/atlas_page_route.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_empty_state.dart';
import '../../../../design_system/widgets/atlas_page_header.dart';
import '../../../../core/location/location_constants.dart';
import '../../../home/presentation/widgets/home_section_header.dart';
import '../../../profile/domain/profile_repository.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/presentation/profile_scope.dart';
import '../../../favorites/presentation/favorites_page_wrapper.dart';
import '../../domain/place_repository.dart';
import '../../domain/models/place_models.dart';
import '../pages/place_detail_page.dart';
import '../widgets/place_category_filter.dart';
import '../widgets/place_guide_card.dart';

/// Répond à : « Que puis-je découvrir autour de moi ? »
class ExplorerPage extends StatefulWidget {
  const ExplorerPage({super.key});

  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends State<ExplorerPage> {
  final PlaceRepository _repository = PlaceRepository();
  final LocationRepository _locationRepository = LocationRepository();
  final TextEditingController _searchController = TextEditingController();

  String _cityName = LocationConstants.fallbackCity;
  bool _isCityCovered = true;
  PlaceCategory? _selectedCategory;
  List<PlaceGuide> _places = const [];
  ProfileRepository? _profileRepository;

  @override
  void initState() {
    super.initState();
    _cityName = _repository.resolveCityName(null);
    _places = _repository.getAll(cityName: _cityName);
    _searchController.addListener(_applyFilters);
    _resolveLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = ProfileScope.of(context);
    if (!identical(repository, _profileRepository)) {
      _profileRepository?.removeListener(_onProfileChanged);
      _profileRepository = repository;
      _profileRepository!.addListener(_onProfileChanged);
    }
  }

  @override
  void dispose() {
    _profileRepository?.removeListener(_onProfileChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onProfileChanged() {
    if (!mounted) return;
    _resolveLocation();
  }

  Future<void> _resolveLocation() async {
    final preferredCity =
        _profileRepository?.profile.preferredCity ?? UserProfile.defaultPreferredCity;
    final location = await _locationRepository.resolveLocation(
      preferredCityName: preferredCity,
    );
    if (!mounted) return;

    setState(() {
      _isCityCovered = _repository.isCityCovered(location.cityName);
      _cityName = _repository.resolveCityName(location.cityName);
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _places = _repository.search(
        PlaceSearchQuery(
          text: _searchController.text,
          category: _selectedCategory,
          cityName: _cityName,
        ),
      );
    });
  }

  void _onCategorySelected(PlaceCategory? category) {
    setState(() => _selectedCategory = category);
    _applyFilters();
  }

  void _openPlace(PlaceGuide place) {
    Navigator.of(context).push(
      AtlasPageRoute<void>(
        page: PlaceDetailPage(place: place),
        wrapPage: (child) => wrapWithFavoritesScope(context, child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AtlasContentContainer(
        child: CustomScrollView(
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
                        : 'Lieux à Marrakech — votre ville n\'est pas encore couverte.',
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un lieu…',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.lg),
                  PlaceCategoryFilter(
                    selectedCategory: _selectedCategory,
                    onCategorySelected: _onCategorySelected,
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  const HomeSectionHeader(title: 'Lieux à découvrir'),
                  const SizedBox(height: AtlasSpacing.lg),
                ],
              ),
            ),
            if (_places.isEmpty)
              const SliverToBoxAdapter(
                child: AtlasEmptyState(
                  message: 'Aucun lieu ne correspond à votre recherche.',
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
