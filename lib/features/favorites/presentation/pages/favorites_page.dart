import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../design_system/navigation/atlas_page_route.dart';
import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_empty_state.dart';
import '../../../../design_system/widgets/atlas_page_header.dart';
import '../../../explorer/domain/place_repository.dart';
import '../../../explorer/presentation/pages/explorer_page.dart';
import '../../../prices/domain/price_intelligence_repository.dart';
import '../../../prices/presentation/pages/prices_page.dart';
import '../../../procedures/domain/procedure_repository.dart';
import '../../../procedures/presentation/pages/procedures_page.dart';
import '../../data/favorites_hub_resolver.dart';
import '../../domain/favorite_entity_type.dart';
import '../../domain/favorites_repository.dart';
import '../../domain/models/favorite_hub_entry.dart';
import '../favorites_page_wrapper.dart';
import '../favorites_scope.dart';
import '../widgets/favorite_toggle_button.dart';

/// Ouvre le hub Favoris (Profile → Favoris).
Future<void> openFavoritesHub(BuildContext context) {
  return Navigator.of(context).push<void>(
    AtlasPageRoute<void>(
      page: const FavoritesPage(),
      wrapPage: (child) => wrapWithFavoritesScope(context, child),
    ),
  );
}

/// Hub de récupération des favoris — lieux, démarches, prix vérifiés.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  FavoritesRepository? _favorites;
  late final PlaceRepository _places = PlaceRepository();
  late final ProcedureRepository _procedures = ProcedureRepository();
  late final PriceIntelligenceRepository _prices =
      PriceIntelligenceRepository();
  bool _warming = true;

  @override
  void initState() {
    super.initState();
    unawaited(_warmCatalogs());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final favorites = FavoritesScope.of(context);
    if (!identical(favorites, _favorites)) {
      _favorites?.removeListener(_onFavoritesChanged);
      _favorites = favorites;
      _favorites!.addListener(_onFavoritesChanged);
      if (!_favorites!.isLoaded) {
        unawaited(_favorites!.load());
      }
    }
  }

  @override
  void dispose() {
    _favorites?.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _warmCatalogs() async {
    await Future.wait([
      _places.warmUp(),
      _procedures.warmUp(),
      _prices.warmUp(),
    ]);
    if (!mounted) return;
    setState(() => _warming = false);
  }

  List<FavoriteHubEntry> get _entries {
    final favorites = _favorites;
    if (favorites == null || !favorites.isLoaded) return const [];
    return FavoritesHubResolver.resolve(
      activeFavorites: favorites.activeFavorites,
      places: _places,
      procedures: _procedures,
      prices: _prices,
    );
  }

  void _openEntry(FavoriteHubEntry entry) {
    if (!entry.isResolved) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Ce contenu n\'est plus disponible dans Atlas. '
              'Vous pouvez le retirer des favoris.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    switch (entry.entityType) {
      case FavoriteEntityType.place:
        openPlaceGuideById(context, _places, entry.entitySlug);
      case FavoriteEntityType.procedure:
        openProcedureGuideById(context, _procedures, entry.entitySlug);
      case FavoriteEntityType.price:
        openPriceObservationById(context, _prices, entry.entitySlug);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _entries;
    final showLoading =
        _warming || _favorites == null || !(_favorites?.isLoaded ?? false);

    return Scaffold(
      appBar: AppBar(title: const Text('Favoris')),
      body: SafeArea(
        child: AtlasContentContainer(
          child: showLoading
              ? const Center(child: CircularProgressIndicator())
              : entries.isEmpty
              ? ListView(
                  padding: const EdgeInsets.only(bottom: AtlasSpacing.section),
                  children: [
                    const SizedBox(height: AtlasSpacing.lg),
                    const AtlasPageHeader(
                      title: 'Mes favoris',
                      subtitle:
                          'Retrouvez vos lieux, démarches et prix '
                          'vérifiés sauvegardés.',
                    ),
                    const SizedBox(height: AtlasSpacing.section),
                    const AtlasEmptyState(
                      icon: Icons.favorite_border,
                      message:
                          'Aucun favori pour le moment. '
                          'Ajoutez un cœur depuis un lieu, une démarche '
                          'ou un prix vérifié.',
                    ),
                    const SizedBox(height: AtlasSpacing.xl),
                    _TypeEmptyHints(theme: theme),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: AtlasSpacing.section),
                  children: [
                    const SizedBox(height: AtlasSpacing.lg),
                    AtlasPageHeader(
                      title: 'Mes favoris',
                      subtitle:
                          '${entries.length} élément'
                          '${entries.length > 1 ? 's' : ''} sauvegardé'
                          '${entries.length > 1 ? 's' : ''} — '
                          'lieux, démarches et prix vérifiés.',
                    ),
                    const SizedBox(height: AtlasSpacing.section),
                    ..._buildGroupedSections(theme, entries),
                  ],
                ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedSections(
    ThemeData theme,
    List<FavoriteHubEntry> entries,
  ) {
    final widgets = <Widget>[];
    for (final type in FavoritesHubResolver.displayOrder) {
      final ofType = entries.where((e) => e.entityType == type).toList();
      widgets.add(
        _TypeSection(type: type, entries: ofType, onOpen: _openEntry),
      );
      widgets.add(const SizedBox(height: AtlasSpacing.section));
    }
    return widgets;
  }
}

class _TypeEmptyHints extends StatelessWidget {
  const _TypeEmptyHints({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final type in FavoritesHubResolver.displayOrder) ...[
          Text(
            switch (type) {
              FavoriteEntityType.place => 'Lieux',
              FavoriteEntityType.procedure => 'Démarches',
              FavoriteEntityType.price => 'Prix vérifiés',
            },
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AtlasSpacing.xs),
          Text(
            switch (type) {
              FavoriteEntityType.place =>
                'Aucun lieu en favori. Ouvrez Explorer pour en ajouter.',
              FavoriteEntityType.procedure =>
                'Aucune démarche en favori. Ouvrez Démarches pour en ajouter.',
              FavoriteEntityType.price =>
                'Aucun prix vérifié en favori. Ouvrez Prix pour en ajouter.',
            },
            style: theme.textTheme.bodySmall?.copyWith(
              color: AtlasColors.midnightBlueMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AtlasSpacing.lg),
        ],
      ],
    );
  }
}

class _TypeSection extends StatelessWidget {
  const _TypeSection({
    required this.type,
    required this.entries,
    required this.onOpen,
  });

  final FavoriteEntityType type;
  final List<FavoriteHubEntry> entries;
  final ValueChanged<FavoriteHubEntry> onOpen;

  String get _title => switch (type) {
    FavoriteEntityType.place => 'Lieux',
    FavoriteEntityType.procedure => 'Démarches',
    FavoriteEntityType.price => 'Prix vérifiés',
  };

  String get _emptyMessage => switch (type) {
    FavoriteEntityType.place => 'Aucun lieu en favori.',
    FavoriteEntityType.procedure => 'Aucune démarche en favori.',
    FavoriteEntityType.price => 'Aucun prix vérifié en favori.',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AtlasSpacing.md),
        if (entries.isEmpty)
          Text(
            _emptyMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AtlasColors.midnightBlueMuted,
            ),
          )
        else
          for (var i = 0; i < entries.length; i++) ...[
            _FavoriteHubTile(
              entry: entries[i],
              onTap: () => onOpen(entries[i]),
            ),
            if (i < entries.length - 1) const SizedBox(height: AtlasSpacing.md),
          ],
      ],
    );
  }
}

class _FavoriteHubTile extends StatelessWidget {
  const _FavoriteHubTile({required this.entry, required this.onTap});

  final FavoriteHubEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AtlasCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            entry.icon,
            color: entry.isResolved
                ? theme.colorScheme.primary
                : AtlasColors.midnightBlueMuted,
          ),
          const SizedBox(width: AtlasSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.xs),
                Text(
                  entry.typeLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AtlasSpacing.sm),
                Text(
                  entry.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (!entry.isResolved) ...[
                  const SizedBox(height: AtlasSpacing.xs),
                  Text(
                    'Contenu non résolu — retirable uniquement.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AtlasColors.midnightBlueMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          FavoriteToggleButton(
            entityType: entry.entityType,
            entitySlug: entry.entitySlug,
          ),
        ],
      ),
    );
  }
}
