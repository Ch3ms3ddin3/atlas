import '../../profile/domain/models/user_profile.dart';
import '../domain/models/assistant_suggestion.dart';

/// Suggestions contextuelles — templates locaux (pas de génération LLM).
abstract final class AssistantSuggestionsCatalog {
  static List<AssistantSuggestion> forProfile({
    required UserProfile profile,
    int vehicleCount = 0,
    int favoriteCount = 0,
  }) {
    final city = profile.preferredCity;
    final type = profile.userType;
    final items = <AssistantSuggestion>[
      AssistantSuggestion(
        id: 'weather-city',
        label: 'Météo à $city',
        prompt: 'Quel temps fait-il aujourd\'hui à $city ? '
            'Utilise uniquement les données Atlas disponibles.',
      ),
      AssistantSuggestion(
        id: 'eur-mad',
        label: 'Cours EUR/MAD',
        prompt: 'Quel est le cours EUR/MAD actuel selon Atlas ?',
      ),
      AssistantSuggestion(
        id: 'events-city',
        label: 'Événements à $city',
        prompt: 'Quels événements ou jours utiles à connaître à $city '
            'cette semaine ?',
      ),
    ];

    switch (type) {
      case AtlasUserType.mre:
      case AtlasUserType.expatriate:
        items.add(
          const AssistantSuggestion(
            id: 'admin-mre',
            label: 'Démarches utiles',
            prompt: 'Quelles démarches administratives sont les plus utiles '
                'pour un MRE ou expatrié au Maroc ?',
          ),
        );
      case AtlasUserType.tourist:
        items.add(
          AssistantSuggestion(
            id: 'tourist-tips',
            label: 'Conseils voyageur',
            prompt: 'Donne-moi 3 conseils pratiques pour un touriste à $city, '
                'sans inventer de prix ni d\'horaires.',
          ),
        );
      case AtlasUserType.student:
        items.add(
          const AssistantSuggestion(
            id: 'student',
            label: 'Vie étudiante',
            prompt: 'Quels repères Atlas peuvent aider un étudiant au Maroc '
                '(démarches, budget, lieux) ?',
          ),
        );
      case AtlasUserType.business:
        items.add(
          AssistantSuggestion(
            id: 'business',
            label: 'Repères business',
            prompt: 'Quels repères Atlas (change, événements, démarches) '
                'sont utiles pour un séjour business à $city ?',
          ),
        );
      case AtlasUserType.resident:
        items.add(
          const AssistantSuggestion(
            id: 'resident',
            label: 'Au quotidien',
            prompt: 'Résume ce qui est utile aujourd\'hui dans Atlas '
                'pour un résident (météo, prière, change, alertes).',
          ),
        );
    }

    if (vehicleCount > 0) {
      items.add(
        const AssistantSuggestion(
          id: 'at-vehicles',
          label: 'Mon Admission Temporaire',
          prompt: 'Où en sont mes véhicules en Admission Temporaire ? '
              'Rappelle les échéances sans inventer de dates.',
        ),
      );
    }
    if (favoriteCount > 0) {
      items.add(
        const AssistantSuggestion(
          id: 'favorites',
          label: 'Mes favoris',
          prompt: 'Aide-moi à tirer parti de mes favoris Atlas.',
        ),
      );
    }

    return items.take(6).toList();
  }
}
