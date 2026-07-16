import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/datetime/last_updated_formatter.dart';
import '../../../../core/notifications/prayer_notification_bootstrap.dart';
import '../../../../core/location/location_constants.dart';
import '../../../../core/location/location_repository.dart';
import '../../../../core/location/user_location.dart';
import '../../../explorer/data/place_mapper.dart';
import '../../../explorer/domain/place_repository.dart';
import '../../../explorer/presentation/pages/explorer_page.dart';
import '../../../favorites/domain/favorite_entity_type.dart';
import '../../../favorites/domain/favorites_repository.dart';
import '../../../favorites/presentation/favorites_scope.dart';
import '../../../prices/domain/models/price_models.dart';
import '../../../prices/domain/price_repository.dart';
import '../../../prices/presentation/pages/prices_page.dart';
import '../../../procedures/domain/models/procedure_models.dart';
import '../../../procedures/domain/procedure_repository.dart';
import '../../../procedures/presentation/pages/procedures_page.dart';
import '../../../profile/domain/profile_repository.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/presentation/profile_scope.dart';
import '../../../shell/presentation/shell_navigation_scope.dart';
import '../../data/exchange_rate/exchange_rate_repository.dart';
import '../../data/greeting/greeting_repository.dart';
import '../../data/holiday/holiday_repository.dart';
import '../../data/home_dashboard_catalog.dart';
import '../../data/mock/home_mock_data.dart';
import '../../data/prayer/prayer_mapper.dart';
import '../../data/prayer/prayer_repository.dart';
import '../../domain/models/exchange_rate_snapshot.dart';
import '../../domain/models/prayer_times_snapshot.dart';
import '../../domain/models/weather_snapshot.dart';
import '../../data/today_essentials/today_essentials_repository.dart';
import '../../data/weather/weather_repository.dart';
import '../widgets/daily_briefing_section.dart';
import '../widgets/greeting_header.dart';
import '../widgets/home_favorites_section.dart';
import '../widgets/home_optional_section.dart';
import '../widgets/home_price_indicators_section.dart';
import '../widgets/home_procedures_section.dart';
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
  final PrayerRepository _prayerRepository = PrayerRepository.instance;
  final ExchangeRateRepository _exchangeRateRepository = ExchangeRateRepository();
  final HolidayRepository _holidayRepository = HolidayRepository();
  final GreetingRepository _greetingRepository = const GreetingRepository();
  final TodayEssentialsRepository _todayEssentialsRepository =
      const TodayEssentialsRepository();
  final ProcedureRepository _procedureRepository = ProcedureRepository();
  final PlaceRepository _placeRepository = PlaceRepository();
  final PriceRepository _priceRepository = PriceRepository();

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
  HolidayStatusData _holidayStatus = HomeMockData.holidayStatus;
  GreetingData _greeting = HomeMockData.greeting;
  TodayEssentialsData _todayEssentials = HomeMockData.todayEssentials;
  String _lastUpdatedLabel = HomeMockData.lastUpdated;
  List<RecommendedPlaceData> _recommendedPlaces = const [];
  List<ProcedureGuide> _curatedProcedures = const [];
  List<PriceGuide> _priceIndicators = const [];
  List<HomeFavoriteEntry> _favoriteEntries = const [];
  DateTime? _weatherFetchedAt;
  DateTime? _prayerFetchedAt;
  DateTime? _exchangeFetchedAt;
  DateTime? _holidayFetchedAt;
  Timer? _prayerCountdownTimer;
  Timer? _dateRollTimer;
  ProfileRepository? _profileRepository;
  FavoritesRepository? _favoritesRepository;
  VoidCallback? _placeCatalogListener;
  VoidCallback? _priceCatalogListener;

  @override
  void initState() {
    super.initState();
    _attachCatalogListeners();
    _refreshDerivedDashboardData();
    _loadCatalogSections();
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
        _loadCatalogSections();
      }
    }

    final favoritesRepository = FavoritesScope.of(context);
    if (!identical(favoritesRepository, _favoritesRepository)) {
      _favoritesRepository?.removeListener(_onFavoritesChanged);
      _favoritesRepository = favoritesRepository;
      _favoritesRepository!.addListener(_onFavoritesChanged);
      _loadFavoriteEntries();
    }
  }

  @override
  void dispose() {
    _profileRepository?.removeListener(_onProfileChanged);
    _favoritesRepository?.removeListener(_onFavoritesChanged);
    _detachCatalogListeners();
    _prayerCountdownTimer?.cancel();
    _dateRollTimer?.cancel();
    super.dispose();
  }

  void _attachCatalogListeners() {
    final places = _placeRepository;
    if (places is Listenable) {
      _placeCatalogListener = _onEditorialCatalogChanged;
      (places as Listenable).addListener(_placeCatalogListener!);
    }
    final prices = _priceRepository;
    if (prices is Listenable) {
      _priceCatalogListener = _onEditorialCatalogChanged;
      (prices as Listenable).addListener(_priceCatalogListener!);
    }
  }

  void _detachCatalogListeners() {
    final places = _placeRepository;
    if (places is Listenable && _placeCatalogListener != null) {
      (places as Listenable).removeListener(_placeCatalogListener!);
    }
    final prices = _priceRepository;
    if (prices is Listenable && _priceCatalogListener != null) {
      (prices as Listenable).removeListener(_priceCatalogListener!);
    }
  }

  void _onEditorialCatalogChanged() {
    if (!mounted) return;
    setState(_loadCatalogSections);
  }

  void _onProfileChanged() {
    if (!mounted) return;
    _refreshDerivedDashboardData();
    _loadCatalogSections();
    unawaited(_resolveLocation());
  }

  void _onFavoritesChanged() {
    if (!mounted) return;
    setState(_loadFavoriteEntries);
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
    _todayEssentials = _todayEssentialsRepository.build(
      weather: _weatherSnapshot.data,
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

  void _loadCatalogSections() {
    final featured = _placeRepository.getFeatured(cityName: _location.cityName);
    _recommendedPlaces = featured
        .map(PlaceMapper.toRecommendedPlaceData)
        .toList();

    _curatedProcedures = HomeDashboardCatalog.resolveCuratedProcedures(
      _procedureRepository.getAll,
    );

    final cityPrices = _priceRepository.getAll(cityName: _location.cityName);
    _priceIndicators = HomeDashboardCatalog.pickUsefulPriceIndicators(
      cityPrices,
    );

    _loadFavoriteEntries();
  }

  void _loadFavoriteEntries() {
    final favorites = _favoritesRepository;
    if (favorites == null || !favorites.isLoaded) {
      _favoriteEntries = const [];
      return;
    }

    final entries = <HomeFavoriteEntry>[];
    for (final key in favorites.activeFavorites) {
      switch (key.entityType) {
        case FavoriteEntityType.place:
          final place = _placeRepository.findById(key.entitySlug);
          if (place == null) continue;
          entries.add(
            HomeFavoriteEntry(
              entityType: FavoriteEntityType.place,
              entitySlug: place.id,
              title: place.name,
              subtitle: '${place.categoryLabel} · ${place.neighborhood}',
              icon: Icons.place_outlined,
            ),
          );
        case FavoriteEntityType.procedure:
          final procedure = _procedureRepository.findById(key.entitySlug);
          if (procedure == null) continue;
          entries.add(
            HomeFavoriteEntry(
              entityType: FavoriteEntityType.procedure,
              entitySlug: procedure.id,
              title: procedure.title,
              subtitle: procedure.categoryLabel,
              icon: procedure.icon,
            ),
          );
        case FavoriteEntityType.price:
          final price = _priceRepository.findById(key.entitySlug);
          if (price == null) continue;
          entries.add(
            HomeFavoriteEntry(
              entityType: FavoriteEntityType.price,
              entitySlug: price.id,
              title: price.name,
              subtitle: '${price.categoryLabel} · ${price.unitLabel}',
              icon: price.icon,
            ),
          );
      }
    }

    entries.sort((a, b) {
      final typeCompare = a.entityType.index.compareTo(b.entityType.index);
      if (typeCompare != 0) return typeCompare;
      return a.title.compareTo(b.title);
    });
    _favoriteEntries = entries;
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
      _loadCatalogSections();
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
    final holidayStatus = await _holidayRepository.getHolidayStatus();
    if (!mounted) return;
    setState(() {
      _holidayStatus = holidayStatus;
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
    setState(_loadCatalogSections);
  }

  void _refreshPrayerCountdown() {
    if (!mounted) return;
    if (!_prayerSnapshot.hasSchedule) return;
    setState(() => _prayerSnapshot = _prayerRepository.buildForNow());
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

  void _onProcedureTap(ProcedureGuide guide) {
    openProcedureGuideById(context, _procedureRepository, guide.id);
  }

  void _onPriceTap(PriceGuide guide) {
    openPriceGuideById(context, _priceRepository, guide.id);
  }

  void _onFavoriteTap(HomeFavoriteEntry entry) {
    switch (entry.entityType) {
      case FavoriteEntityType.place:
        openPlaceGuideById(context, _placeRepository, entry.entitySlug);
      case FavoriteEntityType.procedure:
        openProcedureGuideById(context, _procedureRepository, entry.entitySlug);
      case FavoriteEntityType.price:
        openPriceGuideById(context, _priceRepository, entry.entitySlug);
    }
  }

  void _onQuickActionTap(QuickActionData action) {
    switch (action.id) {
      case 'explorer':
        ShellNavigationScope.goToExplorer(context);
      case 'procedures':
        ShellNavigationScope.goToProcedures(context);
      case 'prices':
        ShellNavigationScope.goToPrices(context);
      case 'profile':
        ShellNavigationScope.goToProfile(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                        weatherSnapshot: _weatherSnapshot,
                        prayerSnapshot: _prayerSnapshot,
                        exchangeRateSnapshot: _exchangeRateSnapshot,
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
                      ),
                    ),
                    AtlasReveal(
                      delay: AtlasMotion.staggerDelay * 5,
                      child: HomeOptionalSection(
                        title: 'Actions rapides',
                        isEmpty: HomeDashboardCatalog.quickActions.isEmpty,
                        topSpacing: AtlasSpacing.section,
                        child: QuickActionsGrid(
                          actions: HomeDashboardCatalog.quickActions,
                          onActionTap: _onQuickActionTap,
                        ),
                      ),
                    ),
                    AtlasReveal(
                      delay: AtlasMotion.staggerDelay * 6,
                      child: HomeOptionalSection(
                        title: 'Mes favoris',
                        isEmpty: _favoriteEntries.isEmpty,
                        child: HomeFavoritesSection(
                          entries: _favoriteEntries,
                          onEntryTap: _onFavoriteTap,
                        ),
                      ),
                    ),
                    AtlasReveal(
                      delay: AtlasMotion.staggerDelay * 7,
                      child: HomeOptionalSection(
                        title: 'Recommandations',
                        isEmpty: _recommendedPlaces.isEmpty,
                        child: RecommendedPlacesSection(
                          places: _recommendedPlaces,
                          onPlaceTap: _onPlaceTap,
                        ),
                      ),
                    ),
                    AtlasReveal(
                      delay: AtlasMotion.staggerDelay * 8,
                      child: HomeOptionalSection(
                        title: 'Démarches utiles',
                        isEmpty: _curatedProcedures.isEmpty,
                        child: HomeProceduresSection(
                          guides: _curatedProcedures,
                          onGuideTap: _onProcedureTap,
                        ),
                      ),
                    ),
                    AtlasReveal(
                      delay: AtlasMotion.staggerDelay * 9,
                      child: HomeOptionalSection(
                        title: 'Repères de prix',
                        isEmpty: _priceIndicators.isEmpty,
                        child: HomePriceIndicatorsSection(
                          guides: _priceIndicators,
                          onGuideTap: _onPriceTap,
                        ),
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
      ),
    );
  }
}
