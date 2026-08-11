import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/datetime/last_updated_formatter.dart';
import '../../../../core/notifications/prayer_notification_bootstrap.dart';
import '../../../../core/location/location_constants.dart';
import '../../../../core/location/location_repository.dart';
import '../../../../core/location/user_location.dart';
import '../../../admission_temporaire/data/at_calculator.dart';
import '../../../admission_temporaire/presentation/at_scope.dart';
import '../../../admission_temporaire/presentation/pages/at_tracker_page.dart';
import '../../../admission_temporaire/presentation/widgets/home_vehicles_card.dart';
import '../../../events/domain/event_repository.dart';
import '../../../events/domain/models/atlas_event.dart';
import '../../../events/presentation/pages/events_calendar_page.dart';
import '../../../events/presentation/widgets/home_events_sections.dart';
import '../../../profile/domain/profile_repository.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/presentation/profile_scope.dart';
import '../../../shell/presentation/shell_navigation_scope.dart';
import '../../data/daily_insight/daily_insight_builder.dart';
import '../../data/exchange_rate/exchange_rate_repository.dart';
import '../../data/greeting/greeting_repository.dart';
import '../../data/home_dashboard_catalog.dart';
import '../../data/morning_brief/morning_brief_builder.dart';
import '../../data/prayer/prayer_mapper.dart';
import '../../data/prayer/prayer_repository.dart';
import '../../domain/models/exchange_rate_snapshot.dart';
import '../../domain/models/home_models.dart';
import '../../domain/models/prayer_times_snapshot.dart';
import '../../domain/models/weather_snapshot.dart';
import '../../data/weather/weather_repository.dart';
import '../widgets/daily_insight_section.dart';
import '../widgets/greeting_header.dart';
import '../widgets/home_section_header.dart';
import '../widgets/morning_brief_section.dart';
import '../widgets/prayer_notification_settings_sheet.dart';
import '../widgets/prayer_time_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/weather_card.dart';
import '../../../../design_system/navigation/atlas_modal.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_motion.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_reveal.dart';
import '../../../admission_temporaire/domain/models/at_vehicle.dart';
import '../../../admission_temporaire/domain/at_repository.dart';
import '../../../prices/domain/models/price_observation.dart';
import '../../../prices/domain/price_intelligence_repository.dart';
import '../../../prices/presentation/pages/prices_page.dart';
import '../../../prices/presentation/widgets/home_price_highlights_section.dart';
import '../widgets/home_optional_section.dart';

/// Home V5 — briefing quotidien premium.
///
/// Répond à : « Qu'est-ce que j'ai besoin de savoir maintenant ? »
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _morningBriefBuilder = MorningBriefBuilder();
  static const _dailyInsightBuilder = DailyInsightBuilder();
  static const _greetingRepository = GreetingRepository();

  final LocationRepository _locationRepository = LocationRepository();
  final WeatherRepository _weatherRepository = WeatherRepository();
  final PrayerRepository _prayerRepository = PrayerRepository.instance;
  final ExchangeRateRepository _exchangeRateRepository =
      ExchangeRateRepository();
  final EventRepository _eventRepository = EventRepository();
  final PriceIntelligenceRepository _prices =
      PriceIntelligenceRepository();

  UserLocation _location = const UserLocation(
    latitude: LocationConstants.fallbackLatitude,
    longitude: LocationConstants.fallbackLongitude,
    cityName: LocationConstants.fallbackCity,
    isFromGps: false,
  );
  WeatherSnapshot _weatherSnapshot = const WeatherSnapshot.loading();
  PrayerTimesSnapshot _prayerSnapshot = const PrayerTimesSnapshot.loading();
  ExchangeRateSnapshot _exchangeRateSnapshot =
      const ExchangeRateSnapshot.loading();
  late GreetingData _greeting = _greetingRepository.build(
    firstName: UserProfile.defaultFirstName,
    city: LocationConstants.fallbackCity,
  );
  String _lastUpdatedLabel = '';
  DateTime? _weatherFetchedAt;
  DateTime? _prayerFetchedAt;
  DateTime? _exchangeFetchedAt;
  Timer? _prayerCountdownTimer;
  Timer? _dateRollTimer;
  ProfileRepository? _profileRepository;
  AtRepository? _atRepository;
  List<AtlasEvent> _todayEvents = const [];
  List<AtlasEvent> _upcomingEvents = const [];
  VoidCallback? _eventCatalogListener;
  VoidCallback? _pricesListener;

  @override
  void initState() {
    super.initState();
    _attachEventListener();
    _attachPricesListener();
    _refreshDerivedDashboardData();
    _refreshEvents();
    _loadWeather();
    _loadPrayerTimes();
    _loadExchangeRate();
    _resolveLocation();
    unawaited(_prices.warmUp());
    _scheduleDateRollTimer();
    _prayerCountdownTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshPrayerCountdown(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profileRepository = ProfileScope.of(context);
    if (!identical(profileRepository, _profileRepository)) {
      _profileRepository?.removeListener(_onProfileChanged);
      _profileRepository = profileRepository;
      _profileRepository!.addListener(_onProfileChanged);
      if (profileRepository.isLoaded) {
        _refreshDerivedDashboardData();
      }
    }
    final atRepository = AtScope.of(context);
    if (!identical(atRepository, _atRepository)) {
      _atRepository?.removeListener(_onAtChanged);
      _atRepository = atRepository;
      _atRepository!.addListener(_onAtChanged);
    }
  }

  @override
  void dispose() {
    _profileRepository?.removeListener(_onProfileChanged);
    _atRepository?.removeListener(_onAtChanged);
    _detachEventListener();
    _detachPricesListener();
    _prayerCountdownTimer?.cancel();
    _dateRollTimer?.cancel();
    super.dispose();
  }

  void _attachEventListener() {
    final events = _eventRepository;
    if (events is Listenable) {
      _eventCatalogListener = _onEventCatalogChanged;
      (events as Listenable).addListener(_eventCatalogListener!);
    }
  }

  void _detachEventListener() {
    final events = _eventRepository;
    if (events is Listenable && _eventCatalogListener != null) {
      (events as Listenable).removeListener(_eventCatalogListener!);
    }
  }

  void _attachPricesListener() {
    final prices = _prices;
    if (prices is Listenable) {
      _pricesListener = _onPricesChanged;
      (prices as Listenable).addListener(_pricesListener!);
    }
  }

  void _detachPricesListener() {
    final prices = _prices;
    if (prices is Listenable && _pricesListener != null) {
      (prices as Listenable).removeListener(_pricesListener!);
    }
  }

  void _onEventCatalogChanged() {
    if (!mounted) return;
    setState(_refreshEvents);
  }

  void _onPricesChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onAtChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onProfileChanged() {
    if (!mounted) return;
    _refreshDerivedDashboardData();
    unawaited(_resolveLocation());
  }

  void _refreshEvents() {
    _todayEvents = _eventRepository.today(cityName: _location.cityName);
    _upcomingEvents = _eventRepository.upcoming(
      cityName: _location.cityName,
      limit: 5,
    );
  }

  AtVehicle? get _urgentVehicle {
    final vehicles = _atRepository?.activeVehicles ?? const [];
    return AtCalculator.mostUrgent(vehicles);
  }

  void _scheduleDateRollTimer() {
    final now = PrayerMapper.casablancaNow();
    final midnight = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    var delay = midnight.difference(now);
    if (delay <= Duration.zero) {
      delay = const Duration(seconds: 1);
    }
    _dateRollTimer?.cancel();
    _dateRollTimer = Timer(delay, () {
      if (mounted) {
        setState(() {
          _refreshDerivedDashboardData();
          _refreshEvents();
        });
        unawaited(_loadPrayerTimes());
      }
      unawaited(prayerNotificationCoordinator.sync(force: true));
      _scheduleDateRollTimer();
    });
  }

  void _refreshDerivedDashboardData() {
    final profile = _profileRepository?.profile ?? UserProfile.defaults;
    _greeting = _greetingRepository.build(
      firstName: profile.firstName,
      city: _location.cityName,
    );
    _lastUpdatedLabel = LastUpdatedFormatter.format([
      _weatherFetchedAt,
      _prayerFetchedAt,
      _exchangeFetchedAt,
    ]);
  }

  Future<void> _resolveLocation() async {
    final preferredCity =
        _profileRepository?.profile.preferredCity ??
        UserProfile.defaultPreferredCity;
    final location = await _locationRepository.resolveLocation(
      preferredCityName: preferredCity,
    );
    if (!mounted) return;

    final locationChanged =
        location.latitude != _location.latitude ||
        location.longitude != _location.longitude ||
        location.cityName != _location.cityName;

    setState(() {
      _location = location;
      _refreshDerivedDashboardData();
      _refreshEvents();
    });

    if (locationChanged) {
      setState(() {
        _weatherSnapshot = const WeatherSnapshot.loading();
        _prayerSnapshot = const PrayerTimesSnapshot.loading();
      });
      await Future.wait([_loadWeather(), _loadPrayerTimes()]);
      unawaited(
        prayerNotificationCoordinator.sync(location: location, force: true),
      );
    }
  }

  Future<void> _loadWeather() async {
    final latitude = _location.latitude;
    final longitude = _location.longitude;
    final snapshot = await _weatherRepository.getWeather(
      latitude: latitude,
      longitude: longitude,
    );
    if (!mounted) return;
    if (latitude != _location.latitude || longitude != _location.longitude) {
      return;
    }
    setState(() {
      _weatherSnapshot = snapshot;
      _weatherFetchedAt = snapshot.hasWeather
          ? snapshot.data?.fetchedAt ?? DateTime.now()
          : null;
      _refreshDerivedDashboardData();
    });
  }

  Future<void> _loadPrayerTimes() async {
    final latitude = _location.latitude;
    final longitude = _location.longitude;
    final snapshot = await _prayerRepository.getPrayerTimes(
      latitude: latitude,
      longitude: longitude,
    );
    if (!mounted) return;
    if (latitude != _location.latitude || longitude != _location.longitude) {
      return;
    }
    setState(() {
      _prayerSnapshot = snapshot;
      _prayerFetchedAt = snapshot.hasSchedule ? DateTime.now() : null;
      _refreshDerivedDashboardData();
    });
    unawaited(prayerNotificationCoordinator.sync(location: _location));
  }

  Future<void> _loadExchangeRate() async {
    final snapshot = await _exchangeRateRepository.getExchangeRate();
    if (!mounted) return;
    setState(() {
      _exchangeRateSnapshot = snapshot;
      _exchangeFetchedAt = snapshot.hasRate
          ? snapshot.data?.fetchedAt ?? DateTime.now()
          : null;
      _refreshDerivedDashboardData();
    });
  }

  Future<void> _refreshAll() async {
    setState(() => _weatherSnapshot = const WeatherSnapshot.loading());
    await _resolveLocation();
    await Future.wait([
      _loadWeather(),
      _loadPrayerTimes(),
      _loadExchangeRate(),
      _prices.refresh(),
    ]);
    if (!mounted) return;
    setState(_refreshEvents);
  }

  void _refreshPrayerCountdown() {
    if (!mounted) return;
    if (!_prayerSnapshot.hasSchedule) return;
    setState(() => _prayerSnapshot = _prayerRepository.buildForNow());
  }

  void _onPrayerCardTap() {
    showAtlasBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => PrayerNotificationSettingsSheet(
        coordinator: prayerNotificationCoordinator,
        onPermissionDenied: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Autorisez les notifications dans les réglages de votre '
                  'téléphone pour activer les rappels de prière.',
                ),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 4),
              ),
            );
        },
      ),
    );
  }

  void _onQuickActionTap(QuickActionData action) {
    switch (action.id) {
      case 'explorer':
        ShellNavigationScope.goToExplorer(context);
      case 'map':
        ShellNavigationScope.goToMap(context);
      case 'procedures':
        ShellNavigationScope.goToProcedures(context);
      case 'prices':
        ShellNavigationScope.goToPrices(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final morningBrief = _morningBriefBuilder.build(
      cityName: _location.cityName,
      weatherSnapshot: _weatherSnapshot,
      prayerSnapshot: _prayerSnapshot,
      exchangeRateSnapshot: _exchangeRateSnapshot,
      todayEvents: _todayEvents,
    );
    final insight = _dailyInsightBuilder.build(
      weatherSnapshot: _weatherSnapshot,
      cityName: _location.cityName,
      todayEvents: _todayEvents,
    );
    final urgentVehicle = _urgentVehicle;
    final hasEventSections =
        _todayEvents.isNotEmpty || _upcomingEvents.isNotEmpty;
    final priceHighlights = _prices.highlights(
      cityName: _location.cityName,
      limit: 3,
    );

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          key: const PageStorageKey<String>('home_scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AtlasContentContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AtlasSpacing.md),
                    // 1. Header
                    AtlasReveal(child: GreetingHeader(data: _greeting)),
                    const SizedBox(height: AtlasSpacing.md),
                    // 2. Aujourd'hui à {ville}
                    AtlasReveal(
                      delay: AtlasMotion.staggerDelay,
                      child: MorningBriefSection(
                        data: morningBrief,
                        onEventsTap: () => openEventsCalendar(
                          context,
                          initialCity: _location.cityName,
                        ),
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.md),
                    // 3. Weather
                    AtlasReveal(
                      delay: AtlasMotion.staggerDelay * 2,
                      child: WeatherCard(snapshot: _weatherSnapshot),
                    ),
                    const SizedBox(height: AtlasSpacing.md),
                    // 4. Prayer
                    AtlasReveal(
                      delay: AtlasMotion.staggerDelay * 2,
                      child: PrayerTimeCard(
                        snapshot: _prayerSnapshot,
                        onTap: _onPrayerCardTap,
                      ),
                    ),
                    // 5. AT — only when the user already tracks a vehicle
                    if (urgentVehicle != null) ...[
                      const SizedBox(height: AtlasSpacing.md),
                      AtlasReveal(
                        delay: AtlasMotion.staggerDelay * 2,
                        child: HomeVehiclesCard(
                          vehicle: urgentVehicle,
                          onTap: () => openVehiclesTracker(context),
                        ),
                      ),
                    ],
                    // 6. Events — hide when empty (no invented filler)
                    if (hasEventSections)
                      AtlasReveal(
                        delay: AtlasMotion.staggerDelay * 3,
                        child: HomeEventsSections(
                          todayEvents: _todayEvents,
                          upcomingEvents: _upcomingEvents,
                          cityName: _location.cityName,
                        ),
                      ),
                    // 7. Trusted price highlights — city-aware, hide if empty
                    AtlasReveal(
                      delay: AtlasMotion.staggerDelay * 3,
                      child: HomeOptionalSection(
                        title: 'Prix à la une',
                        isEmpty: priceHighlights.isEmpty,
                        topSpacing: AtlasSpacing.md,
                        headerSpacing: AtlasSpacing.sm,
                        actionLabel: 'Voir tout',
                        onActionTap: () =>
                            ShellNavigationScope.goToPrices(context),
                        child: HomePriceHighlightsSection(
                          observations: priceHighlights,
                          onObservationTap: (PriceObservation observation) {
                            openPriceObservation(context, observation);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.md),
                    // 8. Quick actions
                    AtlasReveal(
                      delay: AtlasMotion.staggerDelay * 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const HomeSectionHeader(title: 'Actions rapides'),
                          const SizedBox(height: AtlasSpacing.sm),
                          QuickActionsGrid(
                            actions: HomeDashboardCatalog.quickActions,
                            onActionTap: _onQuickActionTap,
                          ),
                        ],
                      ),
                    ),
                    // 9. One contextual tip — only when a real signal exists
                    if (insight != null) ...[
                      const SizedBox(height: AtlasSpacing.md),
                      AtlasReveal(
                        delay: AtlasMotion.staggerDelay * 4,
                        child: DailyInsightSection(data: insight),
                      ),
                    ],
                    if (_lastUpdatedLabel.isNotEmpty) ...[
                      const SizedBox(height: AtlasSpacing.sm),
                      Center(
                        child: Text(
                          _lastUpdatedLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AtlasTextStyles.metadata(theme.colorScheme),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AtlasSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
