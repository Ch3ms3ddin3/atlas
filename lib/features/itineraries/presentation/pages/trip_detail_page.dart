import 'package:flutter/material.dart';

import '../../../../core/uuid/atlas_uuid.dart';
import '../../../../design_system/theme/atlas_colors.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_card.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_filter_chip.dart';
import '../../../../design_system/widgets/atlas_page_header.dart';
import '../../../explorer/domain/models/place_models.dart';
import '../../../explorer/domain/place_repository.dart';
import '../../../favorites/domain/favorite_entity_type.dart';
import '../../../favorites/presentation/favorites_scope.dart';
import '../../domain/itinerary_repository.dart';
import '../../domain/models/itinerary_enums.dart';
import '../../domain/models/itinerary_stop.dart';
import '../../domain/models/trip.dart';
import '../itinerary_scope.dart';

class TripDetailPage extends StatefulWidget {
  const TripDetailPage({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  ItineraryRepository? _repo;
  int _selectedDay = 0;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = ItineraryScope.of(context);
    if (!identical(repo, _repo)) {
      _repo?.removeListener(_onChange);
      _repo = repo;
      _repo!.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    _repo?.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Trip? get _trip => _repo?.findById(widget.tripId);

  Future<void> _optimize() async {
    final trip = _trip;
    if (trip == null || trip.days.isEmpty) return;
    setState(() => _busy = true);
    await _repo!.optimizeDay(trip, trip.days[_selectedDay]);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _addFromFavorites() async {
    final trip = _trip;
    if (trip == null || trip.days.isEmpty) return;
    final favorites = FavoritesScope.of(context).activeFavorites
        .where((f) => f.entityType == FavoriteEntityType.place)
        .toList();
    if (favorites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun lieu favori pour le moment.')),
      );
      return;
    }

    PlaceRepository? places;
    try {
      places = PlaceRepository();
    } catch (_) {
      places = null;
    }

    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('Ajouter depuis les favoris')),
              for (final fav in favorites)
                ListTile(
                  title: Text(
                    places?.findById(fav.entitySlug)?.name ?? fav.entitySlug,
                  ),
                  onTap: () => Navigator.pop(context, fav.entitySlug),
                ),
            ],
          ),
        );
      },
    );
    if (chosen == null || !mounted) return;

    PlaceGuide? place;
    try {
      place = PlaceRepository().findById(chosen);
    } catch (_) {}
    await _repo!.addStop(
      tripId: trip.id,
      dayIndex: _selectedDay,
      stop: ItineraryStop(
        id: AtlasUuid.v4(),
        type: ItineraryStopType.place,
        title: place?.name ?? chosen,
        source: ItineraryStopSource.favorite,
        refId: chosen,
        latitude: place?.latitude,
        longitude: place?.longitude,
        estimatedDurationMin: 90,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = _trip;
    if (trip == null || !trip.isActive) {
      return Scaffold(
        appBar: AppBar(title: const Text('Itinéraire')),
        body: const Center(child: Text('Voyage introuvable.')),
      );
    }

    final day = trip.days.isEmpty
        ? null
        : trip.days[_selectedDay.clamp(0, trip.days.length - 1)];
    final budget = trip.budget;

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.title),
        actions: [
          IconButton(
            tooltip: 'Optimiser le jour',
            onPressed: _busy ? null : _optimize,
            icon: const Icon(Icons.timeline_outlined),
          ),
          IconButton(
            tooltip: 'Ajouter un favori',
            onPressed: _busy ? null : _addFromFavorites,
            icon: const Icon(Icons.favorite_border),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AtlasSpacing.section),
          children: [
            AtlasContentContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AtlasPageHeader(
                    title: trip.primaryCity,
                    subtitle:
                        '${trip.dayCount} jours · rythme ${trip.pace}',
                  ),
                  if (budget?.totalMin != null && budget?.totalMax != null) ...[
                    AtlasCard(
                      emphasis: AtlasCardEmphasis.compact,
                      child: Text(
                        'Budget indicatif : '
                        '${budget!.totalMin!.round()}–${budget.totalMax!.round()} MAD\n'
                        '${budget.notes ?? ''}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.md),
                  ],
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < trip.days.length; i++)
                          Padding(
                            padding:
                                const EdgeInsets.only(right: AtlasSpacing.sm),
                            child: AtlasFilterChip(
                              label: 'J${i + 1}',
                              isSelected: i == _selectedDay,
                              onTap: () => setState(() => _selectedDay = i),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.lg),
                  if (day == null)
                    const Text('Aucune journée')
                  else ...[
                    Text(
                      '${day.cityName} · '
                      '${day.date.day}/${day.date.month}/${day.date.year}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (day.weatherSummary != null) ...[
                      const SizedBox(height: AtlasSpacing.xs),
                      Text(
                        'Météo : ${day.weatherSummary}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AtlasColors.midnightBlueMuted,
                        ),
                      ),
                    ],
                    if (day.prayerSummary != null) ...[
                      Text(
                        'Prières : ${day.prayerSummary}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AtlasColors.midnightBlueMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: AtlasSpacing.lg),
                    if (day.stops.isEmpty)
                      const Text(
                        'Aucun arrêt — ajoutez un favori ou régénérez le voyage.',
                      )
                    else
                      for (var i = 0; i < day.stops.length; i++) ...[
                        if (i > 0 &&
                            day.stops[i].travelFromPreviousMin != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AtlasSpacing.xs,
                            ),
                            child: Text(
                              '↓ ${day.stops[i].travelFromPreviousMin} min'
                              '${day.stops[i].travelDistanceKm != null ? ' · ${day.stops[i].travelDistanceKm!.toStringAsFixed(1)} km' : ''}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AtlasColors.midnightBlueFaint,
                              ),
                            ),
                          ),
                        AtlasCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${i + 1}. ${day.stops[i].title}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AtlasSpacing.xs),
                              Text(
                                [
                                  day.stops[i].type.name,
                                  if (day.stops[i].source ==
                                      ItineraryStopSource.favorite)
                                    'favori',
                                  if (day.stops[i].estimatedDurationMin != null)
                                    '${day.stops[i].estimatedDurationMin} min',
                                ].join(' · '),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AtlasColors.midnightBlueMuted,
                                ),
                              ),
                              if (day.stops[i].notes != null) ...[
                                const SizedBox(height: AtlasSpacing.sm),
                                Text(
                                  day.stops[i].notes!,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AtlasSpacing.sm),
                      ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
