import 'package:flutter/material.dart';

import '../../auth/data/supabase_auth_repository.dart';
import '../../auth/domain/auth_repository.dart';
import '../../auth/presentation/auth_scope.dart';
import '../../admission_temporaire/data/at_bootstrap.dart';
import '../../admission_temporaire/domain/at_repository.dart';
import '../../admission_temporaire/presentation/at_scope.dart';
import '../../content_reports/data/syncing_content_reports_repository.dart';
import '../../content_reports/domain/content_reports_repository.dart';
import '../../content_reports/presentation/content_reports_scope.dart';
import '../../favorites/data/syncing_favorites_repository.dart';
import '../../favorites/domain/favorites_repository.dart';
import '../../favorites/presentation/favorites_scope.dart';
import '../../profile/data/syncing_profile_repository.dart';
import '../../profile/domain/profile_repository.dart';
import '../../profile/presentation/profile_scope.dart';
import '../../explorer/presentation/pages/explorer_page.dart';
import '../../home/presentation/pages/home_page.dart';
import '../../prices/presentation/pages/prices_page.dart';
import '../../procedures/presentation/pages/procedures_page.dart';
import '../../profile/presentation/pages/profile_page.dart';
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
  late final AtRepository _atRepository;
  int _currentIndex = 0;

  static const _pages = <Widget>[
    HomePage(),
    ExplorerPage(),
    ProceduresPage(),
    PricesPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _atRepository = atRepository;
    _authRepository.addListener(_onAuthSessionChanged);
    _authRepository.load();
    _profileRepository.load();
    _favoritesRepository.load();
    _contentReportsRepository.load();
    if (!_atRepository.isLoaded) {
      _atRepository.load();
    }
  }

  @override
  void dispose() {
    _authRepository.removeListener(_onAuthSessionChanged);
    _authRepository.dispose();
    _profileRepository.dispose();
    _favoritesRepository.dispose();
    _contentReportsRepository.dispose();
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
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      repository: _authRepository,
      child: ProfileScope(
        repository: _profileRepository,
        child: FavoritesScope(
          repository: _favoritesRepository,
          child: ContentReportsScope(
            repository: _contentReportsRepository,
            child: AtScope(
              repository: _atRepository,
              child: ShellNavigationScope(
                navigateToTab: _navigateToTab,
                child: Scaffold(
                  body: IndexedStack(
                    index: _currentIndex,
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        ShellTabTransition(
                          isActive: _currentIndex == i,
                          child: _pages[i],
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
  }
}
