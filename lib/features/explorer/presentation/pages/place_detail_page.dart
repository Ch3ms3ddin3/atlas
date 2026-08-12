import 'package:flutter/material.dart';

import '../../../../core/editorial/editorial_catalog_load_state.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_empty_state.dart';
import '../../../content_reports/domain/content_report_entity_type.dart';
import '../../../content_reports/presentation/content_reports_scope.dart';
import '../../../content_reports/presentation/widgets/content_report_sheet.dart';
import '../../../prices/data/place_verified_price_links.dart';
import '../../data/resilient_place_repository.dart';
import '../../domain/models/place_models.dart';
import '../../domain/place_repository.dart';
import '../widgets/place_catalog_status_indicator.dart';
import '../widgets/place_contact_actions.dart';
import '../widgets/place_detail_hero.dart';
import '../widgets/place_detail_section.dart';
import '../widgets/place_editorial_tips.dart';
import '../widgets/place_feature_chips_section.dart';
import '../widgets/place_gallery_section.dart';
import '../widgets/place_opening_hours_section.dart';
import '../widgets/place_verified_price_section.dart';

/// Fiche destination premium — sections conditionnelles selon les données réelles.
class PlaceDetailPage extends StatefulWidget {
  const PlaceDetailPage({super.key, this.place, this.placeId, this.repository})
    : assert(
        place != null || placeId != null,
        'PlaceDetailPage requires place or placeId.',
      );

  /// Snapshot initial (navigation depuis la liste / l'accueil).
  final PlaceGuide? place;

  /// Slug stable — permet le rechargement et l'ouverture hors snapshot.
  final String? placeId;

  /// Injection de test / hors bootstrap ; sinon [PlaceRepository.instance].
  final PlaceRepository? repository;

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  PlaceRepository? _repository;
  VoidCallback? _catalogListener;
  PlaceGuide? _place;
  var _resolving = false;
  var _loadState = EditorialCatalogLoadState.idle;

  String get _slug => widget.placeId ?? widget.place!.id;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? _tryRepositoryInstance();
    _place = widget.place ?? _repository?.findById(_slug);
    _syncLoadState();
    _attachCatalogListener();
    if (_place == null) {
      _resolving = true;
      _warmUpAndResolve();
    }
  }

  @override
  void dispose() {
    _detachCatalogListener();
    super.dispose();
  }

  PlaceRepository? _tryRepositoryInstance() {
    try {
      return PlaceRepository.instance;
    } catch (_) {
      return null;
    }
  }

  void _attachCatalogListener() {
    final repository = _repository;
    if (repository is Listenable) {
      _catalogListener = _onCatalogChanged;
      (repository as Listenable).addListener(_catalogListener!);
    }
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
      final resolved = _repository?.findById(_slug);
      if (resolved != null) {
        _place = resolved;
        _resolving = false;
      } else if (_isSettled(_loadState)) {
        _resolving = false;
      }
    });
  }

  void _syncLoadState() {
    final repository = _repository;
    if (repository is ResilientPlaceRepository) {
      _loadState = repository.loadState;
    } else if (_place != null) {
      _loadState = EditorialCatalogLoadState.success;
    } else {
      _loadState = EditorialCatalogLoadState.idle;
    }
  }

  Future<void> _warmUpAndResolve() async {
    await _repository?.warmUp();
    if (!mounted) return;
    setState(() {
      _syncLoadState();
      _place = _repository?.findById(_slug) ?? _place;
      _resolving = false;
    });
  }

  Future<void> _onRefresh() async {
    await _repository?.warmUp();
    if (!mounted) return;
    setState(() {
      _syncLoadState();
      _place = _repository?.findById(_slug) ?? _place;
    });
  }

  bool _isSettled(EditorialCatalogLoadState state) {
    return state == EditorialCatalogLoadState.success ||
        state == EditorialCatalogLoadState.stale ||
        state == EditorialCatalogLoadState.error;
  }

  Future<void> _openReport() async {
    final place = _place;
    if (place == null) return;
    await showContentReportSheet(
      context: context,
      entityType: ContentReportEntityType.place,
      entitySlug: place.id,
      repository: ContentReportsScope.of(context),
    );
  }

  void _onLaunchFailed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible d\'ouvrir ce lien.')),
    );
  }

  List<String> _galleryUrls(PlaceGuide place) {
    final urls = place.imageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    if (urls.length <= 1) return const [];
    return urls.sublist(1);
  }

  @override
  Widget build(BuildContext context) {
    final place = _place;

    if (place == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lieu')),
        body: SafeArea(child: _buildMissingBody(context)),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        edgeOffset: MediaQuery.paddingOf(context).top + AtlasSpacing.xxxl,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: PlaceDetailHero(
                place: place,
                onReport: _openReport,
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
            SliverToBoxAdapter(
              child: SafeArea(
                top: false,
                child: AtlasContentContainer(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      AtlasSpacing.xl,
                      0,
                      AtlasSpacing.sectionLarge,
                    ),
                    child: _PlaceDetailBody(
                      place: place,
                      loadState: _loadState,
                      galleryUrls: _galleryUrls(place),
                      onLaunchFailed: _onLaunchFailed,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingBody(BuildContext context) {
    if (_resolving) {
      return const Center(child: CircularProgressIndicator());
    }

    return AtlasContentContainer(
      child: ListView(
        children: [
          PlaceCatalogStatusIndicator(loadState: _loadState),
          const AtlasEmptyState(
            icon: Icons.place_outlined,
            message:
                'Lieu introuvable. Ce lieu n\'est pas disponible dans le '
                'catalogue actuel.',
          ),
        ],
      ),
    );
  }
}

class _PlaceDetailBody extends StatelessWidget {
  const _PlaceDetailBody({
    required this.place,
    required this.loadState,
    required this.galleryUrls,
    required this.onLaunchFailed,
  });

  final PlaceGuide place;
  final EditorialCatalogLoadState loadState;
  final List<String> galleryUrls;
  final VoidCallback onLaunchFailed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlaceCatalogStatusIndicator(loadState: loadState),
        Text(
          place.summary,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            height: 1.55,
            fontSize: 17,
          ),
        ),
        if (place.hasBestTimeToVisit) ...[
          const SizedBox(height: AtlasSpacing.section),
          PlaceInfoRow(
            icon: Icons.wb_sunny_outlined,
            label: 'Meilleur moment',
            value: place.bestTimeToVisit!,
          ),
        ],
        if (PlaceVerifiedPriceLinks.hasLinks(place.id)) ...[
          const SizedBox(height: AtlasSpacing.section),
          PlaceVerifiedPriceSection(placeId: place.id),
        ],
        if (place.hasPracticalTips) ...[
          const SizedBox(height: AtlasSpacing.section),
          PlaceEditorialTips(tips: place.practicalTips),
        ],
        if (place.hasAddress) ...[
          const SizedBox(height: AtlasSpacing.section),
          const PlaceDetailSectionHeader(title: 'Adresse'),
          PlaceInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Adresse',
            value: place.address!,
          ),
        ],
        if (place.hasOpeningHours) ...[
          const SizedBox(height: AtlasSpacing.section),
          PlaceOpeningHoursSection(openingHours: place.openingHours!),
        ],
        if (place.hasContactActions) ...[
          const SizedBox(height: AtlasSpacing.section),
          PlaceContactActions(place: place, onLaunchFailed: onLaunchFailed),
        ],
        if (galleryUrls.isNotEmpty) ...[
          const SizedBox(height: AtlasSpacing.section),
          PlaceGallerySection(imageUrls: galleryUrls),
        ],
        if (place.hasAccessibility) ...[
          const SizedBox(height: AtlasSpacing.section),
          PlaceFeatureChipsSection(
            title: 'Accessibilité',
            features: place.accessibilityFeatures,
          ),
        ],
        if (place.hasAmenities) ...[
          const SizedBox(height: AtlasSpacing.section),
          PlaceFeatureChipsSection(
            title: 'Équipements',
            features: place.amenities,
          ),
        ],
        // Breathing room so last section isn't cramped above home indicator.
        const SizedBox(height: AtlasSpacing.md),
        Text(
          'Informations éditoriales Atlas — vérifiez toujours sur place.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AtlasTextStyles.helper(theme.colorScheme),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
