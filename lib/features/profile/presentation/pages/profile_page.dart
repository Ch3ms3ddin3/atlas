import 'package:flutter/material.dart';

import '../../../../design_system/widgets/atlas_placeholder_page.dart';

/// Répond à : « Comment personnaliser mon expérience Atlas ? »
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AtlasPlaceholderPage(
      icon: Icons.person_outline,
      title: 'Profil',
      subtitle:
          'Vos préférences et votre contexte — '
          'touriste, MRE ou expatrié.',
    );
  }
}
