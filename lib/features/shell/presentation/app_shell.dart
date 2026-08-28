import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/config/atlas_env.dart';
import '../../../core/errors/atlas_error_ui.dart';
import '../../../core/location/atlas_city_source.dart';
import '../../../core/network/atlas_connectivity.dart';
import '../../../core/notifications/prayer_notification_bootstrap.dart';
import '../../../core/performance/atlas_performance.dart';
import '../../../core/platform/atlas_build_info.dart';
import '../../../design_system/motion/atlas_haptics.dart';
import '../../../design_system/theme/atlas_colors.dart';
import '../../../design_system/theme/atlas_spacing.dart';
import '../../assistant/data/local_assistant_repository.dart';
import '../../assistant/domain/assistant_repository.dart';
import '../../assistant/presentation/assistant_scope.dart';
import '../../auth/data/auth_session_boundary_controller.dart';
import '../../auth/data/supabase_auth_repository.dart';
import '../../auth/domain/auth_repository.dart';
import '../../auth/presentation/auth_scope.dart';
import '../../admission_temporaire/data/at_bootstrap.dart';
import '../../admission_temporaire/domain/at_repository.dart';
import '../../admission_temporaire/presentation/at_scope.dart';
import '../../beta/data/beta_feedback_repository.dart';
import '../../beta/data/beta_preferences_store.dart';
import '../../beta/domain/changelog_entry.dart';
import '../../beta/presentation/beta_feedback_scope.dart';
import '../../beta/presentation/pages/beta_diagnostics_page.dart';
import '../../beta/presentation/widgets/atlas_beta_banner.dart';
import '../../beta/presentation/widgets/beta_feedback_sheet.dart';
import '../../beta/presentation/widgets/private_beta_expectations_dialog.dart';
import '../../beta/presentation/widgets/whats_new_dialog.dart';
import '../../content_reports/data/syncing_content_reports_repository.dart';
import '../../content_reports/domain/content_reports_repository.dart';
import '../../content_reports/presentation/content_reports_scope.dart';
import '../../explorer/domain/place_browse_filters.dart';
import '../../favorites/data/syncing_favorites_repository.dart';
import '../../favorites/domain/favorites_repository.dart';
import '../../favorites/presentation/favorites_scope.dart';
import '../../itineraries/data/syncing_itinerary_repository.dart';
import '../../itineraries/domain/itinerary_repository.dart';
import '../../itineraries/presentation/itinerary_scope.dart';
import '../../profile/data/syncing_profile_repository.dart';
import '../../profile/domain/profile_repository.dart';
import '../../profile/presentation/profile_scope.dart';
import '../../explorer/presentation/pages/explorer_page.dart';
import '../../home/presentation/pages/home_page.dart';
import '../../map/presentation/pages/atlas_map_page.dart';
import '../../prices/presentation/pages/prices_page.dart';
import '../../procedures/presentation/pages/procedures_page.dart';
import '../../profile/presentation/pages/profile_page.dart';
import '../../sync/data/syncing_user_preferences_repository.dart';
import '../../sync/presentation/sync_scope.dart';
import 'atlas_bottom_nav.dart';
import 'shell_navigation_scope.dart';
import 'shell_tab_scroll_registry.dart';
import 'shell_tab_transition.dart';

/// Coque principale de l'application — navigation par onglets.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.authRepository,
    this.profileRepository,
    this.favoritesRepository,
    this.contentReportsRepository,
  });

  /// Shared with [StartupGate] so recovery deep links use one auth listener.
  final AuthRepository? authRepository;
  final ProfileRepository? profileRepository;

  /// When set (via [AtlasApp]), shares the app-level repository.
  /// Otherwise creates a local instance (e.g. StartupGate in isolation).
  final FavoritesRepository? favoritesRepository;
  final ContentReportsRepository? contentReportsRepository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final AuthRepository _authRepository;
  late final bool _ownsAuthRepository;
  late final ProfileRepository _profileRepository;
  late final bool _ownsProfileRepository;
  late final FavoritesRepository _favoritesRepository;
  late final bool _ownsFavoritesRepository;
  late final ContentReportsRepository _contentReportsRepository;
  late final bool _ownsContentReportsRepository;
  final SyncingUserPreferencesRepository _preferencesRepository =
      SyncingUserPreferencesRepository();
  late final AtRepository _atRepository;
  late final AssistantRepository _assistantRepository;
  late final ItineraryRepository _itineraryRepository;
  late final BetaFeedbackRepository _feedbackRepository;
  final GlobalKey _screenshotKey = GlobalKey();
  int _currentIndex = 0;
  int _bannerTapCount = 0;
  DateTime? _bannerTapWindowStart;
  AtlasBuildInfo? _buildInfo;
  late final AuthSessionBoundaryController _authBoundary;
  late final AtlasConnectivity _connectivity;
  final ShellTabScrollRegistry _tabScrollRegistry = ShellTabScrollRegistry();

  static const _tabNames = {
    AtlasShellTab.home: 'home',
    AtlasShellTab.explorer: 'explorer',
    AtlasShellTab.map: 'map',
    AtlasShellTab.procedures: 'procedures',
    AtlasShellTab.prices: 'prices',
    AtlasShellTab.profile: 'profile',
  };

  @override
  void initState() {
    super.initState();
    _ownsAuthRepository = widget.authRepository == null;
    _authRepository = widget.authRepository ?? SupabaseAuthRepository();
    _ownsProfileRepository = widget.profileRepository == null;
    _profileRepository = widget.profileRepository ?? SyncingProfileRepository();
    _ownsFavoritesRepository = widget.favoritesRepository == null;
    _favoritesRepository =
        widget.favoritesRepository ?? SyncingFavoritesRepository();
    _ownsContentReportsRepository = widget.contentReportsRepository == null;
    _contentReportsRepository =
        widget.contentReportsRepository ?? SyncingContentReportsRepository();
    _atRepository = atRepository;
    _assistantRepository = LocalAssistantRepository(
      profileRepository: _profileRepository,
      authRepository: _authRepository,
      favoritesRepository: _favoritesRepository,
      atRepository: _atRepository,
    );
    _itineraryRepository = SyncingItineraryRepository(
      favoritesRepository: _favoritesRepository,
    );
    _feedbackRepository = BetaFeedbackRepository(
      authRepository: _authRepository,
    );
    _authBoundary = AuthSessionBoundaryController(
      sessionProvider: () => _authRepository.session,
      reloadUserScopedData: _reloadUserScopedData,
    );
    _authRepository.addListener(_onAuthSessionChanged);
    PlaceBrowseFilters.instance.addListener(_onExplorerFiltersChanged);
    _connectivity = AtlasConnectivity();
    _connectivity.addListener(_onConnectivityChanged);
    unawaited(_connectivity.start());
    prayerNotificationCoordinator.bindCloudPersist(
      () => _preferencesRepository.persistFromUi(awaitSync: true),
    );
    if (!_authRepository.isLoaded) {
      _authRepository.load();
    }
    if (!_profileRepository.isLoaded) {
      _profileRepository.load();
    }
    _favoritesRepository.load();
    _contentReportsRepository.load();
    _preferencesRepository.load();
    if (!_atRepository.isLoaded) {
      _atRepository.load();
    }
    _assistantRepository.load();
    _itineraryRepository.load();
    _feedbackRepository.load();
    _loadBuildInfoAndWhatsNew();
  }

  Future<void> _loadBuildInfoAndWhatsNew() async {
    final info = await AtlasBuildInfo.load();
    if (!mounted) return;
    setState(() => _buildInfo = info);

    // Skip beta UX prompts during automated tests.
    if (const bool.fromEnvironment('FLUTTER_TEST')) return;

    final store = const BetaPreferencesStore();
    final expectationsSeen = await store.loadPrivateBetaExpectationsSeen();
    if (!expectationsSeen) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showPrivateBetaExpectationsDialog(context: context);
        await store.savePrivateBetaExpectationsSeen(seen: true);
        if (!mounted) return;
        await _maybeShowWhatsNew(store: store, buildInfo: info);
      });
      return;
    }

    await _maybeShowWhatsNew(store: store, buildInfo: info);
  }

  Future<void> _maybeShowWhatsNew({
    required BetaPreferencesStore store,
    required AtlasBuildInfo buildInfo,
  }) async {
    final lastSeen = await store.loadLastSeenBuild();
    final build = int.tryParse(buildInfo.buildNumber) ?? 0;
    if (build <= lastSeen) return;

    final entries = ChangelogCatalog.sinceBuild(lastSeen);
    if (entries.isEmpty) {
      await store.saveLastSeenBuild(build);
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showWhatsNewDialog(context: context, entries: entries);
      await store.saveLastSeenBuild(build);
    });
  }

  @override
  void dispose() {
    prayerNotificationCoordinator.bindCloudPersist(null);
    PlaceBrowseFilters.instance.removeListener(_onExplorerFiltersChanged);
    _authRepository.removeListener(_onAuthSessionChanged);
    _connectivity.removeListener(_onConnectivityChanged);
    _connectivity.dispose();
    if (_ownsAuthRepository) {
      _authRepository.dispose();
    }
    if (_ownsProfileRepository) {
      _profileRepository.dispose();
    }
    if (_ownsFavoritesRepository) {
      _favoritesRepository.dispose();
    }
    if (_ownsContentReportsRepository) {
      _contentReportsRepository.dispose();
    }
    _preferencesRepository.dispose();
    _assistantRepository.dispose();
    _itineraryRepository.dispose();
    _feedbackRepository.dispose();
    super.dispose();
  }

  void _navigateToTab(int index) {
    if (index == _currentIndex) {
      // Retap active tab → scroll primary content to top (no state reset).
      unawaited(_tabScrollRegistry.scrollToTop(index));
      return;
    }
    final from = _tabNames[_currentIndex] ?? '$_currentIndex';
    final to = _tabNames[index] ?? '$index';
    final sw = Stopwatch()..start();
    setState(() => _currentIndex = index);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      sw.stop();
      AtlasPerformance.recordTabTransition(
        from: from,
        to: to,
        elapsed: sw.elapsed,
      );
    });
  }

  void _onAuthSessionChanged() {
    unawaited(_authBoundary.handleSessionChanged());
  }

  /// Reloads every user-scoped store for the *current* auth session.
  ///
  /// Called by [AuthSessionBoundaryController] after optional clear. Always
  /// re-reads live repositories so a coalesced A→B replay binds B, not A.
  Future<void> _reloadUserScopedData() async {
    await Future.wait([
      _profileRepository.load(),
      _favoritesRepository.load(),
      _contentReportsRepository.load(),
      _preferencesRepository.load(),
      _atRepository.load(),
      _itineraryRepository.load(),
      _assistantRepository.load(),
      _feedbackRepository.load(),
    ]);
    // Await prefs sync so cloud prayer lead-time is applied before OS sync.
    await _preferencesRepository.sync();
    await prayerNotificationCoordinator.sync(force: true);
    // Cancel or rebuild AT OS schedules for the *current* identity (cleared on
    // sign-out; never leave Account A reminders visible for Account B).
    await atNotificationCoordinator.sync(force: true);
  }

  void _onConnectivityChanged() {
    if (mounted) setState(() {});
  }

  void _onExplorerFiltersChanged() {
    _preferencesRepository.persistFromUi();
  }

  void _onBannerTap() {
    final now = DateTime.now();
    if (_bannerTapWindowStart == null ||
        now.difference(_bannerTapWindowStart!) > const Duration(seconds: 3)) {
      _bannerTapWindowStart = now;
      _bannerTapCount = 1;
      return;
    }
    _bannerTapCount += 1;
    if (_bannerTapCount >= 7) {
      _bannerTapCount = 0;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AuthScope(
            repository: _authRepository,
            child: SyncScope(
              repository: _preferencesRepository,
              child: BetaFeedbackScope(
                repository: _feedbackRepository,
                child: const BetaDiagnosticsPage(),
              ),
            ),
          ),
        ),
      );
    }
  }

  String get _currentScreenName =>
      _tabNames[_currentIndex] ?? 'tab_$_currentIndex';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapActive = _currentIndex == AtlasShellTab.map;
    // Bandeau réseau réel (Airplane Mode, etc.) — pas CloudSyncPhase.offline
    // qui signifie « sync réservée au compte » depuis P7.
    final showOffline = _connectivity.isOffline;
    // Bandeau beta — ville seulement si choix manuel (pas le catalogue Marrakech).
    final showBeta = _buildInfo != null;
    final showFeedbackFab = AtlasEnv.fromCompileTime().showBetaFeedback;
    // Bandeau(x) au-dessus du contenu : le padding top iOS est consommé ici
    // pour ne pas le rejouer dans les SafeArea des onglets.
    final hasTopChrome = showBeta || showOffline;

    final tabStack = IndexedStack(
      index: _currentIndex,
      children: [
        ShellTabTransition(
          isActive: _currentIndex == AtlasShellTab.home,
          child: const HomePage(),
        ),
        ShellTabTransition(
          isActive: _currentIndex == AtlasShellTab.explorer,
          child: const ExplorerPage(),
        ),
        ShellTabTransition(
          isActive: mapActive,
          child: AtlasMapPage(isActive: mapActive),
        ),
        ShellTabTransition(
          isActive: _currentIndex == AtlasShellTab.procedures,
          child: const ProceduresPage(),
        ),
        ShellTabTransition(
          isActive: _currentIndex == AtlasShellTab.prices,
          child: const PricesPage(),
        ),
        ShellTabTransition(
          isActive: _currentIndex == AtlasShellTab.profile,
          child: const ProfilePage(),
        ),
      ],
    );

    Widget shell = SyncScope(
      repository: _preferencesRepository,
      child: AtScope(
        repository: _atRepository,
        child: AssistantScope(
          repository: _assistantRepository,
          child: ItineraryScope(
            repository: _itineraryRepository,
            child: BetaFeedbackScope(
              repository: _feedbackRepository,
              child: ShellNavigationScope(
                navigateToTab: _navigateToTab,
                scrollRegistry: _tabScrollRegistry,
                child: Scaffold(
                  floatingActionButtonLocation:
                      FloatingActionButtonLocation.endFloat,
                  floatingActionButton: showFeedbackFab
                      ? Builder(
                          builder: (fabContext) {
                            return FloatingActionButton.small(
                              key: const Key('atlas_beta_feedback_fab'),
                              heroTag: 'atlas_beta_feedback_fab',
                              tooltip: 'Signaler (bêta)',
                              backgroundColor: AtlasColors.surfaceWhite,
                              foregroundColor: theme
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.85),
                              elevation: 1.2,
                              onPressed: () {
                                AtlasHaptics.primaryAction();
                                if (!fabContext.mounted) return;
                                unawaited(
                                  showBetaFeedbackSheet(
                                    context: fabContext,
                                    screenName: _currentScreenName,
                                    screenshotKey: _screenshotKey,
                                    repository: _feedbackRepository,
                                  ),
                                );
                              },
                              child: const Icon(Icons.flag_outlined, size: 20),
                            );
                          },
                        )
                      : null,
                  body: Column(
                    children: [
                      if (showBeta)
                        ListenableBuilder(
                          listenable: _profileRepository,
                          builder: (context, _) {
                            final profile = _profileRepository.profile;
                            final locationLabel =
                                profile.citySource == AtlasCitySource.manual
                                ? profile.preferredCity
                                : null;
                            return AtlasBetaBanner(
                              buildInfo: _buildInfo!,
                              locationLabel: locationLabel,
                              onSecretTap: _onBannerTap,
                            );
                          },
                        ),
                      if (showOffline)
                        SafeArea(
                          // Beta banner déjà sous le status bar → ne pas doubler.
                          top: !showBeta,
                          bottom: false,
                          left: false,
                          right: false,
                          child: const AtlasOfflineNotice(),
                        ),
                      Expanded(
                        child: Padding(
                          // Évite que le FAB masque le bas des listes.
                          padding: EdgeInsets.only(
                            // Compact circular FAB — keep content clear of the control.
                            bottom: showFeedbackFab
                                ? AtlasSpacing.fabClearance
                                : 0,
                          ),
                          child: RepaintBoundary(
                            key: _screenshotKey,
                            child: MediaQuery.removePadding(
                              context: context,
                              // Bandeau beta/offline : le padding top iOS est
                              // déjà consommé par le chrome, pas par les onglets.
                              removeTop: hasTopChrome,
                              // AtlasBottomNav inclut déjà le home indicator.
                              // Sans ça, chaque SafeArea d'onglet rejoue
                              // padding.bottom (~34 pt) et masque le contenu.
                              removeBottom: true,
                              child: tabStack,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: AtlasBottomNav(
                    currentIndex: _currentIndex,
                    onDestinationSelected: _navigateToTab,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // When AtlasApp injects these, scopes already wrap the navigator
    // (modals + pushed routes included). Mount locally only for isolated shells.
    if (_ownsContentReportsRepository) {
      shell = ContentReportsScope(
        repository: _contentReportsRepository,
        child: shell,
      );
    }
    if (_ownsFavoritesRepository) {
      shell = FavoritesScope(repository: _favoritesRepository, child: shell);
    }

    return AuthScope(
      repository: _authRepository,
      child: ProfileScope(repository: _profileRepository, child: shell),
    );
  }
}
