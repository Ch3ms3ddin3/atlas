import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/datetime/atlas_display_clock.dart';
import '../../../../core/location/atlas_city_source.dart';
import '../../../../core/location/location_repository.dart';
import '../../../../core/location/user_location.dart';
import '../../../../core/notifications/prayer_notification_bootstrap.dart';
import '../../../admission_temporaire/data/at_calculator.dart';
import '../../../admission_temporaire/presentation/at_scope.dart';
import '../../../admission_temporaire/presentation/pages/at_tracker_page.dart';
import '../../../admission_temporaire/presentation/widgets/home_vehicles_card.dart';
import '../../../events/domain/event_repository.dart';
import '../../../events/domain/models/atlas_event.dart';
import '../../../events/presentation/pages/events_calendar_page.dart';
import '../../../explorer/domain/place_repository.dart';
import '../../../explorer/presentation/pages/explorer_page.dart';
import '../../../profile/domain/profile_repository.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/presentation/profile_scope.dart';
import '../../../shell/presentation/shell_navigation_scope.dart';
import '../../../shell/presentation/shell_tab_scroll_binding.dart';
import '../../data/exchange_rate/exchange_rate_repository.dart';
import '../../data/greeting/greeting_repository.dart';
import '../../data/morning_brief/morning_brief_builder.dart';
import '../../data/now_actions/home_now_actions_builder.dart';
import '../../data/prayer/prayer_repository.dart';
import '../../data/prayer/prayer_calculation_policy.dart';
import '../../domain/models/exchange_rate_snapshot.dart';
import '../../domain/models/home_models.dart';
import '../../domain/models/prayer_times_snapshot.dart';
import '../../domain/models/weather_snapshot.dart';
import '../../data/weather/weather_repository.dart';
import '../widgets/greeting_header.dart';
import '../widgets/home_now_actions_section.dart';
import '../widgets/morning_brief_section.dart';
import '../widgets/prayer_notification_settings_sheet.dart';
import '../widgets/weather_card.dart';
import '../../../../design_system/navigation/atlas_modal.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_motion.dart';
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

class _HomePageState extends State<HomePage> with ShellTabScrollBinding {
  static const _morningBriefBuilder = MorningBriefBuilder();
  static const _nowActionsBuilder = HomeNowActionsBuilder();
  static const _greetingRepository = GreetingRepository();

  final LocationRepository _locationRepository = LocationRepository();
  final WeatherRepository _weatherRepository = WeatherRepository();
  final PrayerRepository _prayerRepository = PrayerRepository.instance;
  final ExchangeRateRepository _exchangeRateRepository =
      ExchangeRateRepository();
  final EventRepository _eventRepository = EventRepository();
  final PriceIntelligenceRepository _prices = PriceIntelligenceRepository();
  final PlaceRepository _places = PlaceRepository();
  final ScrollController _scrollController = ScrollController();

  @override
  int get shellTabIndex => AtlasShellTab.home;

  @override
  ScrollController get tabScrollController => _scrollController;

  UserLocation _location = UserLocation.catalogFallback;
  WeatherSnapshot _weatherSnapshot = const WeatherSnapshot.loading();
  PrayerTimesSnapshot _prayerSnapshot = const PrayerTimesSnapshot.loading();
  ExchangeRateSnapshot _exchangeRateSnapshot =
      const ExchangeRateSnapshot.loading();
  late GreetingData _greeting = _greetingRepository.build(
    firstName: UserProfile.defaultFirstName,
    city: '',
    citySource: AtlasCitySource.auto,
  );
  Timer? _prayerCountdownTimer;
  Timer? _dateRollTimer;
  ProfileRepository? _profileRepository;
  AtRepository? _atRepository;
  List<AtlasEvent> _todayEvents = const [];
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
    _loadExchangeRate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadPrayerTimes());
    });
    unawaited(_resolveLocation());
    unawaited(_prices.warmUp());
    unawaited(_places.warmUp());
    _scheduleDateRollTimer();
    _prayerCountdownTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshPrayerCountdown(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bindShellTabScroll();
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
    unbindShellTabScroll();
    _profileRepository?.removeListener(_onProfileChanged);
    _atRepository?.removeListener(_onAtChanged);
    _detachEventListener();
    _detachPricesListener();
    _prayerCountdownTimer?.cancel();
    _dateRollTimer?.cancel();
    _scrollController.dispose();
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
    _todayEvents = _eventRepository.today(cityName: _location.catalogCity);
  }

  AtVehicle? get _urgentVehicle {
    final vehicles = _atRepository?.activeVehicles ?? const [];
    return AtCalculator.mostUrgent(vehicles);
  }

  AtlasCitySource get _citySource =>
      _profileRepository?.profile.citySource ?? AtlasCitySource.auto;

  DateTime get _displayNow => AtlasDisplayClock.nowFor(citySource: _citySource);

  void _scheduleDateRollTimer() {
    final now = _displayNow;
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
      city: _location.displayCityName,
      citySource: profile.citySource,
    );
  }

  Future<void> _resolveLocation() async {
    final profile = _profileRepository?.profile ?? UserProfile.defaults;
    final location = await _locationRepository.resolveForProfile(profile);
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
      });
      unawaited(_loadWeather());
    }
    await _loadPrayerTimes();
    unawaited(
      prayerNotificationCoordinator.sync(location: location, force: true),
    );
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
      _refreshDerivedDashboardData();
    });
  }

  Future<void> _loadPrayerTimes() async {
    final plan = PrayerCalculationPolicy.resolve(
      citySource: _citySource,
      location: _location,
    );
    if (!plan.canFetch) {
      if (!mounted) return;
      setState(() {
        _prayerSnapshot = const PrayerTimesSnapshot.needsLocation();
        _refreshDerivedDashboardData();
      });
      unawaited(prayerNotificationCoordinator.sync(location: _location));
      return;
    }

    setState(() {
      _prayerSnapshot = const PrayerTimesSnapshot.loading();
    });

    final latitude = plan.latitude!;
    final longitude = plan.longitude!;
    final snapshot = await _prayerRepository.getPrayerTimes(
      latitude: latitude,
      longitude: longitude,
      referenceTime: _displayNow,
      timeZoneString: plan.timeZoneString,
      method: plan.methodId,
      calculationMethodLabel: plan.methodLabel,
    );
    if (!mounted) return;
    if (latitude != _location.latitude || longitude != _location.longitude) {
      return;
    }
    setState(() {
      _prayerSnapshot = snapshot;
      _refreshDerivedDashboardData();
    });
    unawaited(prayerNotificationCoordinator.sync(location: _location));
  }

  Future<void> _loadExchangeRate() async {
    final snapshot = await _exchangeRateRepository.getExchangeRate();
    if (!mounted) return;
    setState(() {
      _exchangeRateSnapshot = snapshot;
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
      _places.warmUp(),
    ]);
    if (!mounted) return;
    setState(_refreshEvents);
  }

  void _refreshPrayerCountdown() {
    if (!mounted) return;
    if (!_prayerSnapshot.hasSchedule) return;
    setState(
      () => _prayerSnapshot = _prayerRepository.buildForNow(
        referenceTime: _displayNow,
      ),
    );
  }

  void _onPrayerBriefTap() {
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

  void _onWeatherBriefTap() {
    showAtlasBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AtlasSpacing.lg,
            AtlasSpacing.sm,
            AtlasSpacing.lg,
            AtlasSpacing.xxl,
          ),
          child: WeatherCard(snapshot: _weatherSnapshot),
        );
      },
    );
  }

  void _onNowActionTap(HomeNowAction action) {
    switch (action.kind) {
      case HomeNowActionKind.price:
        final id = action.priceObservationId;
        if (id == null) return;
        openPriceObservationById(context, _prices, id);
      case HomeNowActionKind.place:
        final placeId = action.placeId;
        if (placeId == null) return;
        openPlaceGuideById(context, _places, placeId);
      case HomeNowActionKind.map:
        ShellNavigationScope.goToMap(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final morningBrief = _morningBriefBuilder.build(
      cityName: _location.displayCityName,
      weatherSnapshot: _weatherSnapshot,
      prayerSnapshot: _prayerSnapshot,
      exchangeRateSnapshot: _exchangeRateSnapshot,
      todayEvents: _todayEvents,
      referenceTime: _displayNow,
    );
    final nowActions = _nowActionsBuilder.build(
      cityName: _location.catalogCity,
      weatherSnapshot: _weatherSnapshot,
      priceSource: _prices.getAll(),
      placeRepository: _places,
    );
    final urgentVehicle = _urgentVehicle;
    final excludedPriceIds = {
      for (final action in nowActions)
        if (action.priceObservationId != null) action.priceObservationId!,
    };
    final priceHighlights = _prices.homeHighlights(
      cityName: _location.catalogCity,
      limit: 2,
      excludeIds: excludedPriceIds,
    );

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          key: const PageStorageKey<String>('home_scroll'),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AtlasContentContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AtlasSpacing.md),
                    AtlasReveal(
                      child: GreetingHeader(
                        data: _greeting,
                        citySource: _citySource,
                      ),
                    ),
                    const SizedBox(height: AtlasSpacing.md),
                    AtlasReveal(
                      delay: AtlasMotion.staggerDelay,
                      child: MorningBriefSection(
                        data: morningBrief,
                        onWeatherTap: _onWeatherBriefTap,
                        onPrayerTap: _onPrayerBriefTap,
                        onEventsTap: () => openEventsCalendar(
                          context,
                          initialCity: _location.catalogCity,
                        ),
                      ),
                    ),
                    if (nowActions.isNotEmpty) ...[
                      const SizedBox(height: AtlasSpacing.md),
                      AtlasReveal(
                        delay: AtlasMotion.staggerDelay * 2,
                        child: HomeNowActionsSection(
                          actions: nowActions,
                          onActionTap: _onNowActionTap,
                        ),
                      ),
                    ],
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
                    AtlasReveal(
                      delay: AtlasMotion.staggerDelay * 3,
                      child: HomeOptionalSection(
                        title: 'Prix utiles',
                        isEmpty: priceHighlights.isEmpty,
                        topSpacing: AtlasSpacing.md,
                        headerSpacing: AtlasSpacing.sm,
                        actionLabel: 'Voir Prix',
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
