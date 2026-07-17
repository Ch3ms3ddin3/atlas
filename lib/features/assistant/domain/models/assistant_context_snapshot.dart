/// Contexte Atlas figé pour un tour de conversation.
///
/// Ne contient que des faits déjà connus — jamais de valeurs inventées.
class AssistantContextSnapshot {
  const AssistantContextSnapshot({
    required this.city,
    required this.userType,
    required this.language,
    required this.authKind,
    required this.isSignedIn,
    this.firstName,
    this.prayerLeadTimeLabel,
    this.vehicleSummaries = const [],
    this.favoriteSummaries = const [],
    this.weatherSummary,
    this.exchangeRateSummary,
    this.holidaySummary,
    this.eventHighlights = const [],
    this.explorerSummary,
  });

  final String city;
  final String userType;
  final String language;
  final String authKind;
  final bool isSignedIn;
  final String? firstName;
  final String? prayerLeadTimeLabel;
  final List<String> vehicleSummaries;
  final List<String> favoriteSummaries;
  final String? weatherSummary;
  final String? exchangeRateSummary;
  final String? holidaySummary;
  final List<String> eventHighlights;
  final String? explorerSummary;

  Map<String, dynamic> toJson() => {
        'city': city,
        'user_type': userType,
        'language': language,
        'auth_kind': authKind,
        'is_signed_in': isSignedIn,
        if (firstName != null) 'first_name': firstName,
        if (prayerLeadTimeLabel != null)
          'prayer_lead_time': prayerLeadTimeLabel,
        if (vehicleSummaries.isNotEmpty) 'vehicles': vehicleSummaries,
        if (favoriteSummaries.isNotEmpty) 'favorites': favoriteSummaries,
        if (weatherSummary != null) 'weather': weatherSummary,
        if (exchangeRateSummary != null) 'exchange_rate': exchangeRateSummary,
        if (holidaySummary != null) 'holiday': holidaySummary,
        if (eventHighlights.isNotEmpty) 'events': eventHighlights,
        if (explorerSummary != null) 'explorer': explorerSummary,
      };

  /// Bloc texte injecté dans le system prompt / messages provider.
  String toPromptBlock() {
    final lines = <String>[
      'Ville: $city',
      'Profil: $userType',
      'Langue: $language',
      'Session: $authKind',
    ];
    if (firstName != null && firstName!.trim().isNotEmpty) {
      lines.add('Prénom: ${firstName!.trim()}');
    }
    if (prayerLeadTimeLabel != null) {
      lines.add('Rappels prière: $prayerLeadTimeLabel');
    }
    if (vehicleSummaries.isNotEmpty) {
      lines.add('Véhicules AT: ${vehicleSummaries.join(' ; ')}');
    }
    if (favoriteSummaries.isNotEmpty) {
      lines.add('Favoris: ${favoriteSummaries.join(' ; ')}');
    }
    if (weatherSummary != null) lines.add('Météo: $weatherSummary');
    if (exchangeRateSummary != null) {
      lines.add('Change: $exchangeRateSummary');
    }
    if (holidaySummary != null) lines.add('Jour férié: $holidaySummary');
    if (eventHighlights.isNotEmpty) {
      lines.add('Événements: ${eventHighlights.join(' ; ')}');
    }
    if (explorerSummary != null) lines.add('Explorer: $explorerSummary');
    return lines.join('\n');
  }
}
