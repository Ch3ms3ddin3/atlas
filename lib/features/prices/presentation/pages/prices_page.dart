import 'package:flutter/material.dart';

import '../../../../core/location/location_constants.dart';
import '../../../../core/location/location_repository.dart';
import '../../../../design_system/navigation/atlas_page_route.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_empty_state.dart';
import '../../../../design_system/widgets/atlas_page_header.dart';
import '../../../home/presentation/widgets/home_section_header.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/presentation/profile_scope.dart';
import '../../data/price_repository.dart';
import '../../domain/models/price_models.dart';
import '../pages/price_detail_page.dart';
import '../widgets/price_category_filter.dart';
import '../widgets/price_disclaimer_banner.dart';
import '../widgets/price_guide_card.dart';

/// Répond à : « Ce prix est-il normal ? »
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
  ProfileRepository? _profileRepository;

  @override
  void initState() {
    super.initState();
    _cityName = _repository.resolveCityName(null);
    _guides = _repository.getAll(cityName: _cityName);
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
      AtlasPageRoute<void>(
        page: PriceDetailPage(guide: guide),
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
                    title: 'Prix',
                    subtitle:
                        'Repères de prix à $_cityName — pour savoir si un prix '
                        'est normal.',
                    footnote: _isCityCovered
                        ? null
                        : 'Prix à Marrakech — votre ville n\'est pas encore couverte.',
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un poste de dépense…',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.lg),
                  PriceCategoryFilter(
                    selectedCategory: _selectedCategory,
                    onCategorySelected: _onCategorySelected,
                  ),
                  const SizedBox(height: AtlasSpacing.lg),
                  const PriceDisclaimerBanner(),
                  const SizedBox(height: AtlasSpacing.xl),
                  const HomeSectionHeader(title: 'Prix moyens'),
                  const SizedBox(height: AtlasSpacing.lg),
                ],
              ),
            ),
            if (_guides.isEmpty)
              const SliverToBoxAdapter(
                child: AtlasEmptyState(
                  message: 'Aucun prix ne correspond à votre recherche.',
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
    AtlasPageRoute<void>(
      page: PriceDetailPage(guide: guide),
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
