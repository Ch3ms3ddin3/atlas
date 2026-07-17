import 'package:flutter/material.dart';

import '../../assistant/data/local_assistant_repository.dart';
import '../../assistant/domain/assistant_repository.dart';
import '../../assistant/presentation/assistant_scope.dart';
import '../../auth/data/supabase_auth_repository.dart';
import '../../auth/domain/auth_repository.dart';
import '../../auth/presentation/auth_scope.dart';
import '../../admission_temporaire/data/at_bootstrap.dart';
import '../../admission_temporaire/domain/at_repository.dart';
import '../../admission_temporaire/presentation/at_scope.dart';
import '../../content_reports/data/syncing_content_reports_repository.dart';
import '../../content_reports/domain/content_reports_repository.dart';
import '../../content_reports/presentation/content_reports_scope.dart';
import '../../explorer/domain/place_browse_filters.dart';
import '../../favorites/data/syncing_favorites_repository.dart';
import '../../favorites/domain/favorites_repository.dart';
import '../../favorites/presentation/favorites_scope.dart';
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
import 'shell_tab_transition.dart';

/// Coque principale de l'application — navigation par onglets.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final AuthRepository _authRepository = SupabaseAuthRepository();
  final ProfileRepository _profileRepository = SyncingProfileRepository();
  final FavoritesRepository _favoritesRepository = SyncingFavoritesRepository();
  final ContentReportsRepository _contentReportsRepository =
      SyncingContentReportsRepository();
  final SyncingUserPreferencesRepository _preferencesRepository =
      SyncingUserPreferencesRepository();
  late final AtRepository _atRepository;
  late final AssistantRepository _assistantRepository;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _atRepository = atRepository;
    _assistantRepository = LocalAssistantRepository(
      profileRepository: _profileRepository,
      authRepository: _authRepository,
      favoritesRepository: _favoritesRepository,
      atRepository: _atRepository,
    );
    _authRepository.addListener(_onAuthSessionChanged);
    PlaceBrowseFilters.instance.addListener(_onExplorerFiltersChanged);
    _authRepository.load();
    _profileRepository.load();
    _favoritesRepository.load();
    _contentReportsRepository.load();
    _preferencesRepository.load();
    if (!_atRepository.isLoaded) {
      _atRepository.load();
    }
    _assistantRepository.load();
  }

  @override
  void dispose() {
    PlaceBrowseFilters.instance.removeListener(_onExplorerFiltersChanged);
    _authRepository.removeListener(_onAuthSessionChanged);
    _authRepository.dispose();
    _profileRepository.dispose();
    _favoritesRepository.dispose();
    _contentReportsRepository.dispose();
    _preferencesRepository.dispose();
    _assistantRepository.dispose();
    super.dispose();
  }

  void _navigateToTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  void _onAuthSessionChanged() {
    _profileRepository.load();
    _favoritesRepository.load();
    _contentReportsRepository.load();
    _preferencesRepository.load();
    _atRepository.load();
    _assistantRepository.refreshSuggestions();
  }

  void _onExplorerFiltersChanged() {
    _preferencesRepository.persistFromUi();
  }

  @override
  Widget build(BuildContext context) {
    final mapActive = _currentIndex == AtlasShellTab.map;

    return AuthScope(
      repository: _authRepository,
      child: ProfileScope(
        repository: _profileRepository,
        child: FavoritesScope(
          repository: _favoritesRepository,
          child: ContentReportsScope(
            repository: _contentReportsRepository,
            child: SyncScope(
              repository: _preferencesRepository,
              child: AtScope(
                repository: _atRepository,
                child: AssistantScope(
                  repository: _assistantRepository,
                  child: ShellNavigationScope(
                    navigateToTab: _navigateToTab,
                    child: Scaffold(
                      body: IndexedStack(
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
        ),
      ),
    );
  }
}
