import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/notifications/prayer_notification_bootstrap.dart';
import '../../../../core/location/location_constants.dart';
import '../../../../core/location/location_repository.dart';
import '../../../../core/location/user_location.dart';
import '../../data/exchange_rate/exchange_rate_repository.dart';
import '../../data/holiday/holiday_repository.dart';
import '../../data/mock/home_mock_data.dart';
import '../../data/prayer/prayer_mapper.dart';
import '../../data/prayer/prayer_repository.dart';
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
  Timer? _prayerCountdownTimer;
  Timer? _dateRollTimer;

  @override
  void initState() {
    super.initState();
    _prayerTime = _prayerRepository.buildForNow();
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
  void dispose() {
    _prayerCountdownTimer?.cancel();
    _dateRollTimer?.cancel();
    super.dispose();
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
      unawaited(prayerNotificationCoordinator.sync(force: true));
      _scheduleDateRollTimer();
    });
  }

  Future<void> _resolveLocation() async {
    final location = await _locationRepository.resolveLocation();
    if (!mounted) return;

    final locationChanged = location.latitude != _location.latitude ||
        location.longitude != _location.longitude ||
        location.cityName != _location.cityName;

    setState(() => _location = location);

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
    setState(() => _prayerTime = prayerTime);
    unawaited(prayerNotificationCoordinator.sync(location: _location));
  }

  Future<void> _loadExchangeRate() async {
    final exchangeRate = await _exchangeRateRepository.getExchangeRate();
    if (!mounted) return;
    setState(() => _exchangeRate = exchangeRate);
  }

  Future<void> _loadHolidayStatus() async {
    final holidayStatus = await _holidayRepository.getHolidayStatus();
    if (!mounted) return;
    setState(() => _holidayStatus = holidayStatus);
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
            child: HomeContentContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AtlasSpacing.section),
                  AtlasReveal(
                    child: GreetingHeader(
                      data: GreetingData(
                        userName: HomeMockData.greeting.userName,
                        city: _location.cityName,
                        dateLabel: HomeMockData.greeting.dateLabel,
                      ),
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.sectionLarge),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 60),
                    child: const HomeSectionHeader(title: 'Briefing du jour'),
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 100),
                    child: DailyBriefingSection(
                      weather: _weather,
                      isWeatherLoading: _isWeatherLoading,
                      prayerTime: _prayerTime,
                      exchangeRate: _exchangeRate,
                      holidayStatus: _holidayStatus,
                      onPrayerTap: _onPrayerCardTap,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.sectionLarge),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 140),
                    child: const HomeSectionHeader(title: 'À savoir aujourd\'hui'),
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 180),
                    child: TodayEssentialsSection(data: HomeMockData.todayEssentials),
                  ),
                  const SizedBox(height: AtlasSpacing.sectionLarge),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 220),
                    child: const HomeSectionHeader(title: 'Actions rapides'),
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 260),
                    child: QuickActionsGrid(
                      actions: HomeMockData.quickActions,
                      onActionTap: _onQuickActionTap,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.sectionLarge),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 300),
                    child: const HomeSectionHeader(title: 'Administratif'),
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 340),
                    child: AdmissionTemporaireCard(
                      data: HomeMockData.admissionTemporaire,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.sectionLarge),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 380),
                    child: const HomeSectionHeader(title: 'Recommandations'),
                  ),
                  const SizedBox(height: AtlasSpacing.xl),
                  AtlasReveal(
                    delay: const Duration(milliseconds: 420),
                    child: RecommendedPlacesSection(
                      places: HomeMockData.recommendedPlaces,
                    ),
                  ),
                  const SizedBox(height: AtlasSpacing.section),
                  Center(
                    child: Text(
                      HomeMockData.lastUpdated,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.45),
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
