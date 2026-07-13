import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/datetime/last_updated_formatter.dart';
import '../../../../core/notifications/prayer_notification_bootstrap.dart';
import '../../../../core/location/location_constants.dart';
import '../../../../core/location/location_repository.dart';
import '../../../../core/location/user_location.dart';
import '../../../explorer/data/place_mapper.dart';
import '../../../explorer/data/place_repository.dart';
import '../../../explorer/presentation/pages/explorer_page.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/presentation/profile_scope.dart';
import '../../../procedures/data/procedure_reminder_links.dart';
import '../../../procedures/data/procedure_repository.dart';
import '../../../procedures/presentation/pages/procedures_page.dart';
import '../../data/exchange_rate/exchange_rate_repository.dart';
import '../../data/greeting/greeting_repository.dart';
import '../../data/holiday/holiday_repository.dart';
import '../../data/mock/home_mock_data.dart';
import '../../data/prayer/prayer_mapper.dart';
import '../../data/prayer/prayer_repository.dart';
import '../../data/today_essentials/today_essentials_repository.dart';
import '../../data/weather/weather_repository.dart';
import '../widgets/admission_temporaire_card.dart';
import '../widgets/daily_briefing_section.dart';
import '../widgets/greeting_header.dart';
import '../widgets/home_section_header.dart';
import '../widgets/prayer_notification_settings_sheet.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recommended_places_card.dart';
import '../widgets/today_essentials_section.dart';
import '../../../../design_system/theme/atlas_spacing.dart';
import '../../../../design_system/theme/atlas_motion.dart';
import '../../../../design_system/theme/atlas_text_styles.dart';
import '../../../../design_system/widgets/atlas_content_container.dart';
import '../../../../design_system/widgets/atlas_reveal.dart';
import '../../domain/models/home_models.dart';

/// Répond à : « Qu'est-ce que j'ai besoin de savoir maintenant ? »
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocationRepository _locationRepository = LocationRepository();
  final WeatherRepository _weatherRepository = WeatherRepository();
  final PrayerRepository _prayerRepository = PrayerRepository();
  final ExchangeRateRepository _exchangeRateRepository = ExchangeRateRepository();
  final HolidayRepository _holidayRepository = HolidayRepository();
  final GreetingRepository _greetingRepository = const GreetingRepository();
  final TodayEssentialsRepository _todayEssentialsRepository =
      const TodayEssentialsRepository();
  final ProcedureRepository _procedureRepository = const ProcedureRepository();
  final PlaceRepository _placeRepository = const PlaceRepository();

  UserLocation _location = const UserLocation(
    latitude: LocationConstants.fallbackLatitude,
    longitude: LocationConstants.fallbackLongitude,
    cityName: LocationConstants.fallbackCity,
    isFromGps: false,
  );
  WeatherData _weather = HomeMockData.weather;
  bool _isWeatherLoading = true;
  PrayerTimeData _prayerTime = HomeMockData.prayerTime;
  ExchangeRateData _exchangeRate = HomeMockData.exchangeRate;
  HolidayStatusData _holidayStatus = HomeMockData.holidayStatus;
  GreetingData _greeting = HomeMockData.greeting;
  TodayEssentialsData _todayEssentials = HomeMockData.todayEssentials;
  String _lastUpdatedLabel = HomeMockData.lastUpdated;
  List<RecommendedPlaceData> _recommendedPlaces = HomeMockData.recommendedPlaces;
  DateTime? _weatherFetchedAt;
  DateTime? _prayerFetchedAt;
  DateTime? _exchangeFetchedAt;
  DateTime? _holidayFetchedAt;
  Timer? _prayerCountdownTimer;
  Timer? _dateRollTimer;
  ProfileRepository? _profileRepository;

  @override
  void initState() {
    super.initState();
    _prayerTime = _prayerRepository.buildForNow();
    _refreshDerivedDashboardData();
    _loadFeaturedPlaces();
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
    final repository = ProfileScope.of(context);
    if (!identical(repository, _profileRepository)) {
      _profileRepository?.removeListener(_onProfileChanged);
      _profileRepository = repository;
      _profileRepository!.addListener(_onProfileChanged);
      if (repository.isLoaded) {
        _refreshDerivedDashboardData();
      }
    }
  }

  @override
  void dispose() {
    _profileRepository?.removeListener(_onProfileChanged);
    _prayerCountdownTimer?.cancel();
    _dateRollTimer?.cancel();
    super.dispose();
  }

  void _onProfileChanged() {
    if (!mounted) return;
    _refreshDerivedDashboardData();
    unawaited(_resolveLocation());
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
        setState(_refreshDerivedDashboardData);
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
    _todayEssentials = _todayEssentialsRepository.build(
      weather: _weather,
      holidayStatus: _holidayStatus,
      cityName: _location.cityName,
      userType: profile.userType,
    );
    _lastUpdatedLabel = LastUpdatedFormatter.format([
      _weatherFetchedAt,
      _prayerFetchedAt,
      _exchangeFetchedAt,
      _holidayFetchedAt,
    ]);
  }

  void _loadFeaturedPlaces() {
    final featured = _placeRepository.getFeatured(cityName: _location.cityName);
    _recommendedPlaces = featured
        .map(PlaceMapper.toRecommendedPlaceData)
        .toList();
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
      _loadFeaturedPlaces();
    });

    if (locationChanged && location.isFromGps) {
      setState(() => _isWeatherLoading = true);
      await Future.wait([
        _loadWeather(),
        _loadPrayerTimes(),
      ]);
      unawaited(prayerNotificationCoordinator.sync(location: location));
    }
  }

  Future<void> _loadWeather() async {
    final latitude = _location.latitude;
    final longitude = _location.longitude;
    final weather = await _weatherRepository.getWeather(
      latitude: latitude,
      longitude: longitude,
    );
    if (!mounted) return;
    if (latitude != _location.latitude || longitude != _location.longitude) {
      return;
    }
    setState(() {
      _weather = weather;
      _isWeatherLoading = false;
      _weatherFetchedAt = DateTime.now();
      _refreshDerivedDashboardData();
    });
  }

  Future<void> _loadPrayerTimes() async {
    final latitude = _location.latitude;
    final longitude = _location.longitude;
    final prayerTime = await _prayerRepository.getPrayerTimes(
      latitude: latitude,
      longitude: longitude,
    );
    if (!mounted) return;
    if (latitude != _location.latitude || longitude != _location.longitude) {
      return;
    }
    setState(() {
      _prayerTime = prayerTime;
      _prayerFetchedAt = DateTime.now();
      _refreshDerivedDashboardData();
    });
    unawaited(prayerNotificationCoordinator.sync(location: _location));
  }

  Future<void> _loadExchangeRate() async {
    final exchangeRate = await _exchangeRateRepository.getExchangeRate();
    if (!mounted) return;
    setState(() {
      _exchangeRate = exchangeRate;
      _exchangeFetchedAt = DateTime.now();
      _refreshDerivedDashboardData();
    });
  }

  Future<void> _loadHolidayStatus() async {
    final holidayStatus = await _holidayRepository.getHolidayStatus();
    if (!mounted) return;
    setState(() {
      _holidayStatus = holidayStatus;
      _holidayFetchedAt = DateTime.now();
      _refreshDerivedDashboardData();
    });
  }

  void _refreshPrayerCountdown() {
    if (!mounted) return;
    setState(() => _prayerTime = _prayerRepository.buildForNow());
  }

  void _onPrayerCardTap() {
    showModalBottomSheet<void>(
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

  void _onPlaceTap(RecommendedPlaceData place) {
    openPlaceGuideById(context, _placeRepository, place.id);
  }

  void _onAdminReminderTap() {
    final procedureId = ProcedureReminderLinks.procedureIdForReminder(
      _todayEssentials.adminReminder.id,
    );
    if (procedureId == null) return;
    openProcedureGuideById(context, _procedureRepository, procedureId);
  }

  void _onAdmissionTemporaireTap() {
    openProcedureGuideById(
      context,
      _procedureRepository,
      'admission-temporaire',
    );
  }

  void _onQuickActionTap(QuickActionData action) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${action.label} — bientôt disponible'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AtlasContentContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AtlasSpacing.xxl),
                  AtlasReveal(
                    child: GreetingHeader(data: _greeting),
                  ),
                  const SizedBox(height: AtlasSpacing.section),
                  AtlasReveal(
                    delay: AtlasMotion.staggerDelay,
                    child: const HomeSectionHeader(title: 'Briefing du jour'),
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  AtlasReveal(
                    delay: AtlasMotion.staggerDelay * 2,
                    child: DailyBriefingSection(
                      weather: _weather,
                      isWeatherLoading: _isWeatherLoading,
                      prayerTime: _prayerTime,
                      exchangeRate: _exchangeRate,
                      holidayStatus: _holidayStatus,
                      onPrayerTap: _onPrayerCardTap,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.section),
                  AtlasReveal(
                    delay: AtlasMotion.staggerDelay * 3,
                    child: const HomeSectionHeader(title: 'À savoir aujourd\'hui'),
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  AtlasReveal(
                    delay: AtlasMotion.staggerDelay * 4,
                    child: TodayEssentialsSection(
                      data: _todayEssentials,
                      onReminderTap: _onAdminReminderTap,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.section),
                  AtlasReveal(
                    delay: AtlasMotion.staggerDelay * 5,
                    child: const HomeSectionHeader(title: 'Actions rapides'),
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  AtlasReveal(
                    delay: AtlasMotion.staggerDelay * 6,
                    child: QuickActionsGrid(
                      actions: HomeMockData.quickActions,
                      onActionTap: _onQuickActionTap,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.section),
                  AtlasReveal(
                    delay: AtlasMotion.staggerDelay * 7,
                    child: const HomeSectionHeader(title: 'Administratif'),
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  AtlasReveal(
                    delay: AtlasMotion.staggerDelay * 8,
                    child: AdmissionTemporaireCard(
                      data: HomeMockData.admissionTemporaire,
                      onTap: _onAdmissionTemporaireTap,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.section),
                  AtlasReveal(
                    delay: AtlasMotion.staggerDelay * 9,
                    child: const HomeSectionHeader(title: 'Recommandations'),
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  AtlasReveal(
                    delay: AtlasMotion.staggerDelay * 10,
                    child: RecommendedPlacesSection(
                      places: _recommendedPlaces,
                      onPlaceTap: _onPlaceTap,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.section),
                  Center(
                    child: Text(
                      _lastUpdatedLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AtlasTextStyles.metadata(theme.colorScheme),
                      ),
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.sectionLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
