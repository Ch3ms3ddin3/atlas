import 'package:flutter/material.dart';

import '../../../../core/editorial/editorial_catalog_load_state.dart';
import '../../../../design_system/navigation/atlas_page_route.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_empty_state.dart';
import '../../../../design_system/widgets/atlas_page_header.dart';
import '../../data/event_query.dart';
import '../../data/resilient_event_repository.dart';
import '../../domain/event_repository.dart';
import '../../domain/models/atlas_event.dart';
import '../widgets/event_catalog_status_indicator.dart';
import '../widgets/event_filters_bar.dart';
import '../widgets/event_list_tile_card.dart';
import 'event_detail_page.dart';

/// Ouvre l'agenda Maroc.
Future<void> openEventsCalendar(
  BuildContext context, {
  String? initialCity,
}) {
  return Navigator.of(context).push<void>(
    AtlasPageRoute<void>(
      page: EventsCalendarPage(initialCity: initialCity),
    ),
  );
}

Future<void> openEventDetail(BuildContext context, String eventId) {
  return Navigator.of(context).push<void>(
    AtlasPageRoute<void>(
      page: EventDetailPage(eventId: eventId),
    ),
  );
}

/// Agenda chronologique avec filtres catégorie / ville.
class EventsCalendarPage extends StatefulWidget {
  const EventsCalendarPage({
    super.key,
    this.initialCity,
  });

  final String? initialCity;

  @override
  State<EventsCalendarPage> createState() => _EventsCalendarPageState();
}

class _EventsCalendarPageState extends State<EventsCalendarPage> {
  late final EventRepository _repository;
  EventCategory? _category;
  String? _city;
  EditorialCatalogLoadState _loadState = EditorialCatalogLoadState.idle;

  @override
  void initState() {
    super.initState();
    _repository = EventRepository();
    _city = widget.initialCity;
    _syncLoadState();
    if (_repository is Listenable) {
      (_repository as Listenable).addListener(_onRepoChanged);
    }
    _repository.warmUp();
  }

  @override
  void dispose() {
    if (_repository is Listenable) {
      (_repository as Listenable).removeListener(_onRepoChanged);
    }
    super.dispose();
  }

  void _onRepoChanged() {
    if (!mounted) return;
    setState(_syncLoadState);
  }

  void _syncLoadState() {
    final repository = _repository;
    if (repository is ResilientEventRepository) {
      _loadState = repository.loadState;
    } else {
      _loadState = EditorialCatalogLoadState.idle;
    }
  }

  List<AtlasEvent> get _filtered {
    return _repository.search(
      EventSearchQuery(
        cityName: _city,
        category: _category,
        includeNational: true,
        from: EventQuery.calendarDay(EventQuery.casablancaNow()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final events = _filtered;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 840;

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda Maroc')),
      body: SafeArea(
        child: AtlasContentContainer(
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 320,
                      child: ListView(
                        padding: const EdgeInsets.only(
                          top: AtlasSpacing.lg,
                          bottom: AtlasSpacing.section,
                          right: AtlasSpacing.xl,
                        ),
                        children: [
                          EventCatalogStatusIndicator(loadState: _loadState),
                          const AtlasPageHeader(
                            title: 'Agenda',
                            subtitle:
                                'Dates utiles pour résidents, MRE et voyageurs.',
                            footnote:
                                'Festivals et dates religieuses uniquement '
                                'lorsqu\'elles sont publiées et sourcées.',
                          ),
                          const SizedBox(height: AtlasSpacing.xl),
                          EventFiltersBar(
                            selectedCategory: _category,
                            selectedCity: _city,
                            onCategorySelected: (value) =>
                                setState(() => _category = value),
                            onCitySelected: (value) =>
                                setState(() => _city = value),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: _EventList(events: events)),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: AtlasSpacing.section),
                  children: [
                    const SizedBox(height: AtlasSpacing.lg),
                    EventCatalogStatusIndicator(loadState: _loadState),
                    const AtlasPageHeader(
                      title: 'Agenda Maroc',
                      subtitle:
                          'Dates utiles pour résidents, MRE et voyageurs.',
                      footnote:
                          'Festivals et dates religieuses uniquement '
                          'lorsqu\'elles sont publiées et sourcées.',
                    ),
                    const SizedBox(height: AtlasSpacing.xl),
                    EventFiltersBar(
                      selectedCategory: _category,
                      selectedCity: _city,
                      onCategorySelected: (value) =>
                          setState(() => _category = value),
                      onCitySelected: (value) => setState(() => _city = value),
                    ),
                    const SizedBox(height: AtlasSpacing.section),
                    if (events.isEmpty)
                      const AtlasEmptyState(
                        icon: Icons.event_busy_outlined,
                        message:
                            'Aucun événement ne correspond à ces filtres '
                            'pour le moment.',
                      )
                    else
                      ..._groupedTiles(theme, events),
                  ],
                ),
        ),
      ),
    );
  }

  List<Widget> _groupedTiles(ThemeData theme, List<AtlasEvent> events) {
    final widgets = <Widget>[];
    String? lastKey;
    for (final event in events) {
      final key =
          '${event.startAt.year}-${event.startAt.month.toString().padLeft(2, '0')}';
      if (key != lastKey) {
        lastKey = key;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(
              top: AtlasSpacing.lg,
              bottom: AtlasSpacing.md,
            ),
            child: Text(
              '${_monthLabel(event.startAt.month)} ${event.startAt.year}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AtlasSpacing.md),
          child: EventListTileCard(
            event: event,
            onTap: () => openEventDetail(context, event.id),
          ),
        ),
      );
    }
    return widgets;
  }

  String _monthLabel(int month) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return months[month - 1];
  }
}

class _EventList extends StatelessWidget {
  const _EventList({required this.events});

  final List<AtlasEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
        child: AtlasEmptyState(
          icon: Icons.event_busy_outlined,
          message:
              'Aucun événement ne correspond à ces filtres pour le moment.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AtlasSpacing.lg),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: AtlasSpacing.md),
      itemBuilder: (context, index) {
        final event = events[index];
        return EventListTileCard(
          event: event,
          onTap: () => openEventDetail(context, event.id),
        );
      },
    );
  }
}
