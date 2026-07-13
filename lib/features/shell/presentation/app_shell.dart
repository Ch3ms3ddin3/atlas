import 'package:flutter/material.dart';

import '../../profile/data/profile_repository.dart';
import '../../profile/presentation/profile_scope.dart';
import '../../explorer/presentation/pages/explorer_page.dart';
import '../../home/presentation/pages/home_page.dart';
import '../../prices/presentation/pages/prices_page.dart';
import '../../procedures/presentation/pages/procedures_page.dart';
import '../../profile/presentation/pages/profile_page.dart';
import 'atlas_bottom_nav.dart';

/// Coque principale de l'application — navigation par onglets.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final ProfileRepository _profileRepository = ProfileRepository();
  int _currentIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    return ProfileScope(
      repository: _profileRepository,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            HomePage(),
            ExplorerPage(),
            ProceduresPage(),
            PricesPage(),
            ProfilePage(),
          ],
        ),
        bottomNavigationBar: AtlasBottomNav(
          currentIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
        ),
      ),
    );
  }
}
