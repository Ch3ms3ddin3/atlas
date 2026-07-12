import 'package:flutter/material.dart';

import '../../../../core/location/location_repository.dart';
import '../../../home/presentation/widgets/home_section_header.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../core/location/location_constants.dart';
import '../../data/place_repository.dart';
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
  final PlaceRepository _repository = const PlaceRepository();
  final LocationRepository _locationRepository = LocationRepository();
  final TextEditingController _searchController = TextEditingController();

  String _cityName = LocationConstants.fallbackCity;
  bool _isCityCovered = true;
  PlaceCategory? _selectedCategory;
  List<PlaceGuide> _places = const [];

  @override
  void initState() {
    super.initState();
    _cityName = _repository.resolveCityName(null);
    _places = _repository.getAll(cityName: _cityName);
    _searchController.addListener(_applyFilters);
    _resolveLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _resolveLocation() async {
    final location = await _locationRepository.resolveLocation();
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
      MaterialPageRoute<void>(
        builder: (_) => PlaceDetailPage(place: place),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: HomeContentContainer(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AtlasSpacing.section),
                  Text(
                    'Explorer',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.sm),
                  Text(
                    'Lieux utiles à $_cityName — découvertes curatées par Atlas.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  if (!_isCityCovered) ...[
                    const SizedBox(height: AtlasSpacing.sm),
                    Text(
                      'Lieux à Marrakech — votre ville n\'est pas encore couverte.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                  const SizedBox(height: AtlasSpacing.xl),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un lieu…',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
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
              SliverToBoxAdapter(
                child: Text(
                  'Aucun lieu ne correspond à votre recherche.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
    MaterialPageRoute<void>(
      builder: (_) => PlaceDetailPage(place: place),
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
