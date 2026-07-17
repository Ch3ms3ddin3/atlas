/// Suggestion de question contextuelle (chip).
class AssistantSuggestion {
  const AssistantSuggestion({
    required this.id,
    required this.label,
    required this.prompt,
  });

  final String id;
  final String label;
  final String prompt;
}
