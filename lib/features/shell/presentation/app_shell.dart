import 'package:flutter/material.dart';

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
  final ProfileRepository _profileRepository = SyncingProfileRepository();
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
    _profileRepository.load();
  }

  @override
  void dispose() {
    _profileRepository.dispose();
    super.dispose();
  }

  void _navigateToTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return ProfileScope(
      repository: _profileRepository,
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
    );
  }
}
