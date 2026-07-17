import 'models/assistant_context_snapshot.dart';

/// Snippet RAG prêt pour une future indexation Atlas.
class AssistantKnowledgeSnippet {
  const AssistantKnowledgeSnippet({
    required this.id,
    required this.title,
    required this.content,
    this.source,
    this.score,
  });

  final String id;
  final String title;
  final String content;
  final String? source;
  final double? score;
}

/// Source de connaissances — stub RAG (pas d'embeddings dans ce milestone).
abstract class AssistantKnowledgeSource {
  Future<List<AssistantKnowledgeSnippet>> retrieve({
    required String query,
    required AssistantContextSnapshot context,
    int limit = 5,
  });
}

/// Source vide — défaut v1.
class EmptyKnowledgeSource implements AssistantKnowledgeSource {
  const EmptyKnowledgeSource();

  @override
  Future<List<AssistantKnowledgeSnippet>> retrieve({
    required String query,
    required AssistantContextSnapshot context,
    int limit = 5,
  }) async =>
      const [];
}

/// Injecte le snapshot Atlas comme « documents » locaux (pré-RAG).
class InMemoryAtlasContextSource implements AssistantKnowledgeSource {
  const InMemoryAtlasContextSource();

  @override
  Future<List<AssistantKnowledgeSnippet>> retrieve({
    required String query,
    required AssistantContextSnapshot context,
    int limit = 5,
  }) async {
    return [
      AssistantKnowledgeSnippet(
        id: 'atlas-context',
        title: 'Contexte utilisateur Atlas',
        content: context.toPromptBlock(),
        source: 'atlas_context_snapshot',
        score: 1,
      ),
    ].take(limit).toList();
  }
}
