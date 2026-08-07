import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/datetime/last_updated_formatter.dart';
import '../../../../core/notifications/prayer_notification_bootstrap.dart';
import '../../../../core/location/location_constants.dart';
import '../../../../core/location/location_repository.dart';
import '../../../../core/location/user_location.dart';
import '../../../events/domain/event_repository.dart';
import '../../../events/domain/models/atlas_event.dart';
import '../../../profile/domain/profile_repository.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/presentation/profile_scope.dart';
import '../../../shell/presentation/shell_navigation_scope.dart';
import '../../data/daily_insight/daily_insight_builder.dart';
import '../../data/exchange_rate/exchange_rate_repository.dart';
import '../../data/greeting/greeting_repository.dart';
import '../../data/holiday/holiday_repository.dart';
import '../../data/home_dashboard_catalog.dart';
import '../../data/morning_brief/morning_brief_builder.dart';
import '../../data/pour_vous/pour_vous_builder.dart';
import '../../data/mock/home_mock_data.dart';
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
import '../widgets/pour_vous_section.dart';
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
  static const _pourVousBuilder = PourVousBuilder();
  static const _dailyInsightBuilder = DailyInsightBuilder();

  final LocationRepository _locationRepository = LocationRepository();
  final WeatherRepository _weatherRepository = WeatherRepository();
  final PrayerRepository _prayerRepository = PrayerRepository.instance;
  final ExchangeRateRepository _exchangeRateRepository = ExchangeRateRepository();
  final HolidayRepository _holidayRepository = HolidayRepository();
  final GreetingRepository _greetingRepository = const GreetingRepository();
  final EventRepository _eventRepository = EventRepository();

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
  GreetingData _greeting = HomeMockData.greeting;
  String _lastUpdatedLabel = HomeMockData.lastUpdated;
  DateTime? _weatherFetchedAt;
  DateTime? _prayerFetchedAt;
  DateTime? _exchangeFetchedAt;
  DateTime? _holidayFetchedAt;
  Timer? _prayerCountdownTimer;
  Timer? _dateRollTimer;
  ProfileRepository? _profileRepository;
  List<AtlasEvent> _todayEvents = const [];
  VoidCallback? _eventCatalogListener;

  @override
  void initState() {
    super.initState();
    _attachEventListener();
    _refreshDerivedDashboardData();
    _refreshEvents();
    _loadWeather();
    _loadPrayerTimes();
    _loadExchangeRate();
    _loadHolidayStatus();
    _resolveLocation();
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
  }

  @override
  void dispose() {
    _profileRepository?.removeListener(_onProfileChanged);
    _detachEventListener();
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

  void _onEventCatalogChanged() {
    if (!mounted) return;
    setState(_refreshEvents);
  }

  void _onProfileChanged() {
    if (!mounted) return;
    _refreshDerivedDashboardData();
    unawaited(_resolveLocation());
  }

  void _refreshEvents() {
    _todayEvents = _eventRepository.today(cityName: _location.cityName);
  }

  void _scheduleDateRollTimer() {
    final now = PrayerMapper.casablancaNow();
    final midnight = DateTime(now.year, now.month, now.day).add(
      const Duration(days: 1),
    );
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
      _holidayFetchedAt,
    ]);
  }

  Future<void> _resolveLocation() async {
    final preferredCity =
        _profileRepository?.profile.preferredCity ?? UserProfile.defaultPreferredCity;
    final location = await _locationRepository.resolveLocation(
      preferredCityName: preferredCity,
    );
    if (!mounted) return;

    final locationChanged = location.latitude != _location.latitude ||
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
      await Future.wait([
        _loadWeather(),
        _loadPrayerTimes(),
      ]);
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
      _exchangeFetchedAt =
          snapshot.hasRate ? snapshot.data?.fetchedAt ?? DateTime.now() : null;
      _refreshDerivedDashboardData();
    });
  }

  Future<void> _loadHolidayStatus() async {
    await _holidayRepository.getHolidayStatus();
    if (!mounted) return;
    setState(() {
      _holidayFetchedAt = DateTime.now();
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
      _loadHolidayStatus(),
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
    final pourVous = _pourVousBuilder.build(
      weatherSnapshot: _weatherSnapshot,
      cityName: _location.cityName,
    );
    final insight = _dailyInsightBuilder.build(
      weatherSnapshot: _weatherSnapshot,
      cityName: _location.cityName,
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
                    AtlasReveal(
                      child: GreetingHeader(data: _greeting),
                    ),
                    const SizedBox(height: AtlasSpacing.md),
                    // 2. Aujourd'hui à {ville}
                    AtlasReveal(
                      delay: AtlasMotion.staggerDelay,
                      child: MorningBriefSection(data: morningBrief),
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
                    const SizedBox(height: AtlasSpacing.md),
                    // 5. Pour vous
                    AtlasReveal(
                      delay: AtlasMotion.staggerDelay * 3,
                      child: PourVousSection(recommendations: pourVous),
                    ),
                    const SizedBox(height: AtlasSpacing.md),
                    // 6. Quick actions (secondary)
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
                    const SizedBox(height: AtlasSpacing.md),
                    // 7. Daily insight
                    AtlasReveal(
                      delay: AtlasMotion.staggerDelay * 4,
                      child: DailyInsightSection(data: insight),
                    ),
                    const SizedBox(height: AtlasSpacing.sm),
                    Center(
                      child: Text(
                        _lastUpdatedLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AtlasTextStyles.metadata(theme.colorScheme),
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
