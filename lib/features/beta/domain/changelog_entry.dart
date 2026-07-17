/// Entrée de changelog pour le dialogue « Nouveautés ».
class ChangelogEntry {
  const ChangelogEntry({
    required this.version,
    required this.buildNumber,
    required this.title,
    required this.bullets,
  });

  final String version;
  final int buildNumber;
  final String title;
  final List<String> bullets;
}

/// Catalogue local des notes de version (ordre décroissant de build).
abstract final class ChangelogCatalog {
  static const List<ChangelogEntry> entries = [
    ChangelogEntry(
      version: '1.0.0',
      buildNumber: 2,
      title: 'Atlas Private Beta',
      bullets: [
        'Signalement in-app pour les testeurs',
        'Bannière Private Beta et diagnostics',
        'Messages d’erreur plus clairs + réessai',
        'Durcissement production readiness',
      ],
    ),
    ChangelogEntry(
      version: '1.0.0',
      buildNumber: 1,
      title: 'Première build privée',
      bullets: [
        'Accueil, Explorer, Carte, Démarches, Prix',
        'Assistant Atlas et itinéraires',
        'Synchronisation cloud locale-first',
      ],
    ),
  ];

  static ChangelogEntry? latestForBuild(int buildNumber) {
    for (final entry in entries) {
      if (entry.buildNumber == buildNumber) return entry;
    }
    return entries.isEmpty ? null : entries.first;
  }

  static List<ChangelogEntry> sinceBuild(int lastSeenBuild) {
    return [
      for (final entry in entries)
        if (entry.buildNumber > lastSeenBuild) entry,
    ];
  }
}
