import 'package:flutter/material.dart';

import '../../../../core/location/location_constants.dart';
import '../../../../core/location/location_repository.dart';
import '../../../home/presentation/widgets/home_section_header.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../data/price_repository.dart';
import '../../domain/models/price_models.dart';
import '../pages/price_detail_page.dart';
import '../widgets/price_category_filter.dart';
import '../widgets/price_guide_card.dart';

/// Répond à : « Combien coûte la vie ici ? »
class PricesPage extends StatefulWidget {
  const PricesPage({super.key});

  @override
  State<PricesPage> createState() => _PricesPageState();
}

class _PricesPageState extends State<PricesPage> {
  final PriceRepository _repository = const PriceRepository();
  final LocationRepository _locationRepository = LocationRepository();
  final TextEditingController _searchController = TextEditingController();

  String _cityName = LocationConstants.fallbackCity;
  bool _isCityCovered = true;
  PriceCategory? _selectedCategory;
  List<PriceGuide> _guides = const [];

  @override
  void initState() {
    super.initState();
    _cityName = _repository.resolveCityName(null);
    _guides = _repository.getAll(cityName: _cityName);
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
      _guides = _repository.search(
        PriceSearchQuery(
          text: _searchController.text,
          category: _selectedCategory,
          cityName: _cityName,
        ),
      );
    });
  }

  void _onCategorySelected(PriceCategory? category) {
    setState(() => _selectedCategory = category);
    _applyFilters();
  }

  void _openGuide(PriceGuide guide) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PriceDetailPage(guide: guide),
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
                    'Prix',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.sm),
                  Text(
                    'Repères de prix à $_cityName — pour planifier votre quotidien.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  if (!_isCityCovered) ...[
                    const SizedBox(height: AtlasSpacing.sm),
                    Text(
                      'Prix à Marrakech — votre ville n\'est pas encore couverte.',
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
                      hintText: 'Rechercher un poste de dépense…',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.lg),
                  PriceCategoryFilter(
                    selectedCategory: _selectedCategory,
                    onCategorySelected: _onCategorySelected,
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  const HomeSectionHeader(title: 'Prix moyens'),
                  const SizedBox(height: AtlasSpacing.lg),
                ],
              ),
            ),
            if (_guides.isEmpty)
              SliverToBoxAdapter(
                child: Text(
                  'Aucun prix ne correspond à votre recherche.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              SliverList.separated(
                itemCount: _guides.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AtlasSpacing.lg),
                itemBuilder: (context, index) {
                  final guide = _guides[index];
                  return PriceGuideCard(
                    guide: guide,
                    onTap: () => _openGuide(guide),
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

/// Ouvre un repère de prix depuis n'importe quel écran.
void openPriceGuide(BuildContext context, PriceGuide guide) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PriceDetailPage(guide: guide),
    ),
  );
}

/// Ouvre un repère de prix par identifiant ; ne fait rien si introuvable.
void openPriceGuideById(
  BuildContext context,
  PriceRepository repository,
  String priceId,
) {
  final guide = repository.findById(priceId);
  if (guide == null) return;
  openPriceGuide(context, guide);
}
